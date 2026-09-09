// Pipeline → Notification seeder (Approach C — Hybrid robust).
// Pure service: reads KRS cache → scheduleAll overwrite, dedup via hash.

import 'package:flutter/foundation.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/utils/schedule_helpers.dart';
import 'package:lonceng_unman_fe/features/krs/data/models/krs_model.dart';
import 'package:lonceng_unman_fe/features/krs/domain/entities/krs_entity.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';

enum SeedResultKind { seeded, skipped, failed }

class SeedResult {
  const SeedResult(this.kind, this.count, this.reason);
  final SeedResultKind kind;
  final int count;
  final String? reason;

  static SeedResult ok(int n) => SeedResult(SeedResultKind.seeded, n, null);
  static SeedResult skip(String r) => SeedResult(SeedResultKind.skipped, 0, r);
  static SeedResult fail(String r) => SeedResult(SeedResultKind.failed, 0, r);
}

/// Reads KRS from AcademicCache and seeds notifications via NotificationCubit.
/// Idempotent via hash dedup + _isSeeding guard; handles KRS empty/miss/permission.
class PipelineNotificationSeeder {
  PipelineNotificationSeeder({
    AcademicCacheService? cache,
    NotificationLocalDataSource? notifDataSource,
    NotificationCubit Function()? cubitProvider,
  }) : _cache = cache,
       _notifDS = notifDataSource,
       _cubitProvider = cubitProvider;

  final AcademicCacheService? _cache;
  final NotificationLocalDataSource? _notifDS;
  final NotificationCubit Function()? _cubitProvider;

  static const String kLastSeedHashKey = 'pipeline_lastSeedHash';
  static const String kLastSeedAtKey = 'pipeline_lastSeedAt';
  static const String kClearedManuallyKey = 'pipeline_clearedManually';

  bool _isSeeding = false;

  AcademicCacheService get _ac =>
      _cache ?? Services.get<AcademicCacheService>();
  NotificationLocalDataSource get _nds =>
      _notifDS ?? Services.get<NotificationLocalDataSource>();
  NotificationCubit _cubit() {
    final p = _cubitProvider;
    if (p != null) return p();
    return Services.get<NotificationCubit>();
  }

  /// Stable hash over schedule items (courseName|dayOfWeek|HH:MM sorted).
  static String hashItems(List<ScheduleItemEntity> items) {
    final parts =
        items
            .map(
              (e) =>
                  '${e.courseName}|${e.dayOfWeek}|${e.startTime.hour.toString().padLeft(2, '0')}:${e.startTime.minute.toString().padLeft(2, '0')}',
            )
            .toList()
          ..sort();
    return parts.join(';').hashCode.toString();
  }

  Future<SeedResult> seedFromCache({String? npm}) async {
    if (_isSeeding) {
      debugPrint('[SEEDER] skip — already seeding');
      return SeedResult.skip('dedup_inflight');
    }
    _isSeeding = true;
    try {
      String? resolvedNpm = npm;
      if (resolvedNpm == null || resolvedNpm.isEmpty) {
        final creds = await _ac.loadCredentials();
        resolvedNpm = creds?['npm'];
      }
      if (resolvedNpm == null || resolvedNpm.isEmpty) {
        return SeedResult.skip('no_npm');
      }

      final krsJson = await _ac.loadKrsData(npm: resolvedNpm);
      if (krsJson == null) {
        debugPrint('[SEEDER] krs cache miss npm=$resolvedNpm');
        return SeedResult.skip('krs_cache_miss');
      }

      // krsJson is {krs:{mata_kuliah:[], ...}, metadata:{}} — parse via KrsModel
      // Hive returns Map<dynamic,dynamic>, normalize to Map<String,dynamic> for fromJson casts.
      late final List<MataKuliahKrsEntity> mataKuliahEntities;
      try {
        final normalized = _normalizeJson(krsJson);
        final krsModel = KrsModel.fromJson(normalized);
        mataKuliahEntities = krsModel.krs.mataKuliah;
      } catch (e) {
        debugPrint('[SEEDER] KrsModel parse failed: $e');
        return SeedResult.fail('krs_parse:$e');
      }

      if (mataKuliahEntities.isEmpty) {
        debugPrint('[SEEDER] krs_empty — clearing stale if any');
        try {
          final existing = _nds.getAll();
          if (existing.isNotEmpty) {
            final cubit = _cubit();
            await cubit.cancelAll();
            await _nds.settingsBox.put(kClearedManuallyKey, false);
          }
        } catch (e) {
          debugPrint('[SEEDER] krs_empty cancel failed: $e');
        }
        try {
          await _nds.settingsBox.put(kLastSeedHashKey, 'empty');
          await _nds.settingsBox.put(
            kLastSeedAtKey,
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (_) {}
        return SeedResult.skip('krs_empty');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      late final List<ScheduleItemEntity> items;
      try {
        items = mataKuliahEntities
            .map((mk) => toScheduleItem(mk, today, now))
            .toList();
      } catch (e) {
        debugPrint('[SEEDER] toScheduleItem failed: $e');
        return SeedResult.fail('toScheduleItem:$e');
      }

      final hash = hashItems(items);
      String? lastHash;
      try {
        lastHash = _nds.settingsBox.get(kLastSeedHashKey) as String?;
      } catch (_) {}
      if (lastHash != null && lastHash == hash) {
        debugPrint('[SEEDER] dedup skip hash=$hash');
        return SeedResult.skip('dedup');
      }

      bool cleared = false;
      try {
        cleared = _nds.settingsBox.get(kClearedManuallyKey) == true;
      } catch (_) {}
      if (cleared) {
        debugPrint('[SEEDER] skip — pipeline_clearedManually true');
        return SeedResult.skip('cleared_manually');
      }

      // Try via cubit first; fallback to direct scheduler if cubit not mounted yet
      // (fresh-login: DataInitSuccess fires in LoginPage before ShellRoute mounts)
      bool viaCubit = true;
      late final NotificationCubit cubit;
      try {
        cubit = _cubit();
      } catch (_) {
        viaCubit = false;
      }

      if (viaCubit) {
        try {
          await cubit.scheduleAll(items);
        } catch (e) {
          debugPrint('[SEEDER] scheduleAll threw: $e');
          return SeedResult.fail('scheduleAll:$e');
        }
        final st = cubit.state;
        if (st.status == NotificationStatus.error) {
          debugPrint('[SEEDER] scheduleAll ended in error: ${st.errorMessage}');
          return SeedResult.fail(st.errorMessage ?? 'permission_denied');
        }
      } else {
        // Direct path: schedule via NotificationScheduler + NotificationService
        debugPrint('[SEEDER] no cubit — scheduling directly via scheduler');
        try {
          final scheduler = Services.get<NotificationScheduler>();
          // Check permission via NotificationService directly
          final svc = Services.get<NotificationService>();
          final hasPerm = await svc.checkPermissionStatus();
          bool granted = hasPerm;
          if (!granted) {
            granted = await svc.requestPermission();
          }
          if (!granted) {
            debugPrint('[SEEDER] permission denied (direct)');
            return SeedResult.fail('permission_denied');
          }
          await scheduler.scheduleAllDays(items);
          // scheduleAllDays already calls _saveOptimistic + saveAll internally
          // Hash will be saved below
        } catch (e) {
          debugPrint('[SEEDER] direct schedule failed: $e');
          return SeedResult.fail('direct:$e');
        }
        // Also need to persist pipeline hash even for direct path — done below
      }

      try {
        await _nds.settingsBox.put(kLastSeedHashKey, hash);
        await _nds.settingsBox.put(
          kLastSeedAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        await _nds.settingsBox.put(kClearedManuallyKey, false);
      } catch (e) {
        debugPrint('[SEEDER] hash save failed: $e');
      }
      debugPrint('[SEEDER] seeded ${items.length} hash=$hash');
      return SeedResult.ok(items.length);
    } catch (e) {
      debugPrint('[SEEDER] failed: $e');
      return SeedResult.fail(e.toString());
    } finally {
      _isSeeding = false;
    }
  }

  Map<String, dynamic> _normalizeJson(Map src) {
    Map<String, dynamic> convert(Map m) {
      return m.map((k, v) {
        if (v is Map) {
          return MapEntry(k.toString(), convert(v));
        }
        if (v is List) {
          return MapEntry(
            k.toString(),
            v.map((e) => e is Map ? convert(e) : e).toList(),
          );
        }
        return MapEntry(k.toString(), v);
      });
    }

    return convert(src);
  }
}
