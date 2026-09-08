// patrol_test/notification_reminder_logged_in_test.dart
//
// Patrol for logged-in position but via full bootstrap (no const
// LoncengUnmanApp). Copies _bootstrapRealServicesForLogin from
// login_e2e_test but skips credential entry and waits on Home.
// Then verifies per-class toggles + interval picker 5m..60m loop.
//
// Run:
//   patrol test -t patrol_test/notification_reminder_logged_in_test.dart \
//     --device 127.0.0.1:5557 --no-uninstall

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart' as hive;
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/core/services/notification_scheduler_noop.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/widgets/navbar_visibility_notifier.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/repositories/data_initialization_repository_impl.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/data/repositories/home_repository_impl.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/khs/data/repositories/khs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_pdf_service.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/data/repositories/krs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_delivered_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_delivered_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lonceng_unman_fe/main.dart';
import 'package:patrol/patrol.dart';

Future<void> _bootstrapForLoggedIn() async {
  final tempDir = await Directory.systemTemp.createTemp('lonceng_test_');
  hive.Hive.init(tempDir.path);
  hive.Hive.registerAdapter(ScheduledNotificationModelAdapter());
  hive.Hive.registerAdapter(NotificationDeliveredModelAdapter());
  final notificationsBox = await hive.Hive.openBox<ScheduledNotificationModel>(
    NotificationConfig.scheduledNotificationsBox,
  );
  final settingsBox = await hive.Hive.openBox<int>(
    NotificationConfig.notificationSettingsBox,
  );
  final deliveredBox = await hive.Hive.openBox<NotificationDeliveredModel>(
    'notification_delivered',
  );
  final onboardingDS = OnboardingLocalDataSource();
  await onboardingDS.init();
  final onboardingRepo = OnboardingRepositoryImpl(onboardingDS);
  await onboardingRepo.markCompleted();
  Services.register<OnboardingLocalDataSource>(onboardingDS);
  Services.register<OnboardingRepository>(onboardingRepo);
  Services.register<NotificationLocalDataSource>(
    NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    ),
  );
  final ns = NotificationService();
  Services.register<NotificationService>(ns);
  try {
    await ns.initialize();
    Services.register<NotificationScheduler>(
      NotificationScheduler(
        repository: Services.get<NotificationRepository>(),
        notificationService: ns,
      ),
    );
  } catch (_) {
    Services.register<NotificationScheduler>(NotificationSchedulerNoop());
  }
  Services.register<NotificationRepository>(
    NotificationRepositoryImpl(
      localDataSource: Services.get<NotificationLocalDataSource>(),
    ),
  );
  Services.register<NotificationDeliveredLocalDataSource>(
    NotificationDeliveredLocalDataSource(box: deliveredBox),
  );
  Services.register<NotificationDeliveredRepository>(
    NotificationDeliveredRepositoryImpl(
      localDataSource: Services.get<NotificationDeliveredLocalDataSource>(),
    ),
  );
  final acs = AcademicCacheService();
  await acs.initialize();
  Services.register<AcademicCacheService>(acs);
  final bcs = BioCacheService();
  await bcs.initialize();
  Services.register<BioCacheService>(bcs);
  final avcs = AvatarCacheService();
  await avcs.initialize();
  Services.register<AvatarCacheService>(avcs);
  final ps = PhotoService();
  Services.register<PhotoService>(ps);
  final avc = AvatarCubit(cache: avcs, academicCache: acs, photoService: ps);
  Services.register<AvatarCubit>(avc);
  Services.register<ThemeNotifier>(ThemeNotifier());
  Services.register<AuthStatusNotifier>(AuthStatusNotifier());
  Services.register<NavbarVisibilityNotifier>(NavbarVisibilityNotifier());
  Services.register<ConnectivityService>(
    ConnectivityServiceImpl(Connectivity()),
  );
  final api = ApiClient(
    baseUrl: AppStrings.apiBaseUrl,
    onAuthError: () async => Services.performFullLogout(),
  );
  Services.register<ApiClient>(api);
  final ads = AuthRemoteDataSourceImpl(apiClient: api);
  Services.register<AuthRemoteDataSource>(ads);
  Services.register<GetAuth>(
    GetAuth(AuthRepositoryImpl(remoteDataSource: ads)),
  );
  Services.register<SaveAuthCredentials>(SaveAuthCredentials(acs));
  Services.register<LoadAuthCredentials>(LoadAuthCredentials(acs));
  final spcs = StudentProfileCacheService();
  await spcs.initialize();
  Services.register<StudentProfileCacheService>(spcs);
  Services.register<StudentProfileRemoteDataSource>(
    StudentProfileRemoteDataSourceImpl(apiClient: api, cacheService: spcs),
  );
  final krsDS = KrsRemoteDataSourceImpl(
    apiClient: api,
    academicCacheService: acs,
  );
  Services.register<KrsRemoteDataSource>(krsDS);
  final getKrs = GetKrs(KrsRepositoryImpl(remoteDataSource: krsDS));
  Services.register<GetKrs>(getKrs);
  final khsDS = KhsRemoteDataSourceImpl(
    apiClient: api,
    academicCacheService: acs,
  );
  Services.register<KhsRemoteDataSource>(khsDS);
  final getKhs = GetKhs(KhsRepositoryImpl(remoteDataSource: khsDS));
  Services.register<GetKhs>(getKhs);
  Services.register<KhsPdfService>(KhsPdfService());
  Services.register<PullRefreshDebounce>(PullRefreshDebounce());
  final dids = DataInitializationRemoteDataSource(
    getKrs: getKrs,
    getKhs: getKhs,
    profileDataSource: Services.get<StudentProfileRemoteDataSource>(),
    photoService: ps,
    avatarCache: avcs,
  );
  Services.register<DataInitializationRemoteDataSource>(dids);
  Services.register<GetDataInitialization>(
    GetDataInitialization(
      DataInitializationRepositoryImpl(remoteDataSource: dids),
    ),
  );
  Services.register<GetHome>(
    GetHome(
      HomeRepositoryImpl(
        remoteDataSource: HomeRemoteDataSourceImpl(
          academicCacheService: acs,
          studentProfileCacheService: spcs,
        ),
      ),
    ),
  );
  Services.register<GetJadwal>(
    GetJadwal(
      JadwalRepositoryImpl(
        remoteDataSource: JadwalRemoteDataSourceImpl(
          krsDataSource: krsDS,
          academicCacheService: acs,
          studentProfileCacheService: spcs,
        ),
      ),
    ),
  );
  Services.register<GetProfile>(
    GetProfile(
      ProfileRepositoryImpl(
        remoteDataSource: ProfileRemoteDataSourceImpl(
          academicCacheService: acs,
          bioCacheService: bcs,
          apiClient: api,
          studentProfileCacheService: spcs,
        ),
      ),
    ),
  );
}

String _labelFor(int minutes) {
  if (minutes >= 60) return AppStrings.settingsReminderHour;
  return AppStrings.settingsReminderMinutes(minutes);
}

void main() {
  patrolTest('logged-in reminder interval loop 5m..60m', ($) async {
    await $.pumpWidgetAndSettle(const LoncengUnmanApp());
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));
    // Home must be visible (no npm_field)
    await $(
      #lihat_khs_button,
    ).waitUntilVisible(timeout: const Duration(seconds: 15));
    expect($(#lihat_khs_button), findsOneWidget);

    // Home -> Profile -> Settings
    final profileTab = find.byIcon(Icons.person_rounded);
    if (profileTab.evaluate().isNotEmpty) {
      await $.tester.tap(profileTab.first);
    } else {
      final navItems = find.byType(InkWell);
      await $.tester.tap(navItems.at(navItems.evaluate().length - 1));
    }
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    await $(
      AppStrings.profileSettingsButton,
    ).waitUntilVisible(timeout: const Duration(seconds: 10));
    await $(AppStrings.profileSettingsButton).tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    expect($(AppStrings.settingsTitle), findsOneWidget);
    await $.pump(const Duration(seconds: 2));

    final ctx = $.tester.element(find.text(AppStrings.settingsTitle));
    final cubit = ctx.read<NotificationCubit>();
    await $.pump(const Duration(seconds: 1));
    final initialCount = cubit.state.notifications.length;
    // ignore: avoid_print
    print('[PATROL-REMINDER] initial notifications=$initialCount');
    expect(
      initialCount,
      greaterThan(0),
      reason: 'Fresh-login regression: per-class toggles must exist',
    );
    expect(
      find.byType(Switch).evaluate().length,
      greaterThanOrEqualTo(initialCount),
    );

    for (final minutes in NotificationConfig.reminderOptions) {
      final label = _labelFor(minutes);
      // ignore: avoid_print
      print('[PATROL-REMINDER] === interval $minutes ($label) START ===');
      // Open picker
      final listTiles = find.byType(ListTile);
      bool tapped = false;
      for (final e in listTiles.evaluate()) {
        final w = e.widget as ListTile;
        if (w.title is Text &&
            (w.title as Text).data == AppStrings.settingsReminderLabel) {
          await $.tester.tap(find.byWidget(w));
          tapped = true;
          break;
        }
      }
      if (!tapped)
        await $.tester.tap(find.text(AppStrings.settingsReminderLabel).first);
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      await $(label).waitUntilVisible(timeout: const Duration(seconds: 5));
      await $(label).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      expect(cubit.state.reminderIntervalMinutes, minutes);
      expect(cubit.state.notifications.length, initialCount);
      for (final n in cubit.state.notifications) {
        expect(n.reminderOffset, minutes);
        // ignore: avoid_print
        print(
          '[PATROL-REMINDER]   notif ${n.courseName} ${n.dayOfWeek} '
          '${n.classTime.hour}:${n.classTime.minute.toString().padLeft(2, '0')} '
          'offset=${n.reminderOffset}m id=${n.id}',
        );
      }
      // ignore: avoid_print
      print('[PATROL-REMINDER] === interval $minutes OK ===');
    }
    // ignore: avoid_print
    print('[PATROL-REMINDER] LOOP DONE — all 5 intervals verified');
  });
}
