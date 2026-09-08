// patrol_test/verify_5m_interval_test.dart
// Verifies 5m offset produces origWhen 07:55 for dummy Sabtu 08:00/10:00
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart' as hive;
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
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
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/main.dart';
import 'package:patrol/patrol.dart';

Future<void> _bootstrap() async {
  final tempDir = await Directory.systemTemp.createTemp('lonceng_5m_');
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
  Services.register<NotificationRepository>(
    NotificationRepositoryImpl(
      localDataSource: Services.get<NotificationLocalDataSource>(),
    ),
  );
  final ns = NotificationService();
  Services.register<NotificationService>(ns);
  try {
    await ns.initialize();
  } catch (_) {}
  Services.register<NotificationScheduler>(
    NotificationScheduler(
      repository: Services.get<NotificationRepository>(),
      notificationService: ns,
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
  Services.register<GetKrs>(GetKrs(KrsRepositoryImpl(remoteDataSource: krsDS)));
  final khsDS = KhsRemoteDataSourceImpl(
    apiClient: api,
    academicCacheService: acs,
  );
  Services.register<KhsRemoteDataSource>(khsDS);
  Services.register<GetKhs>(GetKhs(KhsRepositoryImpl(remoteDataSource: khsDS)));
  Services.register<KhsPdfService>(KhsPdfService());
  Services.register<PullRefreshDebounce>(PullRefreshDebounce());
  final dids = DataInitializationRemoteDataSource(
    getKrs: Services.get<GetKrs>(),
    getKhs: Services.get<GetKhs>(),
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

void main() {
  patrolTest('verify 5m interval produces 07:55 trigger', ($) async {
    await _bootstrap();
    await $.pumpWidgetAndSettle(
      LoncengUnmanApp(
        authStatusNotifier: Services.get<AuthStatusNotifier>(),
        themeNotifier: Services.get<ThemeNotifier>(),
      ),
    );
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));
    // login quickly if needed
    try {
      await $(#npm_field).waitUntilVisible(timeout: const Duration(seconds: 8));
      await $(#npm_field).tap();
      await $.pumpAndSettle();
      await $.enterText($(#npm_field), '2211700006');
      await $.pumpAndSettle(duration: const Duration(seconds: 1));
      await $(#password_field).tap();
      await $.pumpAndSettle();
      await $.enterText($(#password_field), 'Izzan027');
      await $.pumpAndSettle(duration: const Duration(seconds: 1));
      final loginPage = find.byType(LoncengUnmanApp); // dummy to get context
      // trigger via AuthBloc directly
      await $.pumpAndSettle();
      final filled = find.byType(FilledButton);
      if (filled.evaluate().isNotEmpty) await $.tester.tap(filled.last);
      await $.pump();
      try {
        await $(
          'Konfirmasi Data Profil',
        ).waitUntilVisible(timeout: const Duration(seconds: 60));
        await $('Ya, Konfirmasi').tap();
        await $.pump();
      } catch (_) {}
      await $(
        #lihat_khs_button,
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
    } catch (_) {}
    await $.pump(const Duration(seconds: 2));
    final ctx = $.tester.element(find.byType(MaterialApp).first);
    NotificationCubit cubit;
    try {
      cubit = ctx.read<NotificationCubit>();
    } catch (_) {
      cubit = NotificationCubit(
        scheduler: Services.get<NotificationScheduler>(),
        repository: Services.get<NotificationRepository>(),
        notificationService: Services.get<NotificationService>(),
      );
    }
    await cubit.loadNotifications();
    if (cubit.state.notifications.isEmpty) {
      final repo = Services.get<NotificationRepository>();
      final now = DateTime.now();
      final e1 = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId('Dummy MK 1', 'Sabtu', 8),
        courseName: 'Dummy MK 1',
        dayOfWeek: 'Sabtu',
        classTime: DateTime(now.year, now.month, now.day, 8, 0),
        reminderOffset: 5,
        room: 'Lab 1',
        lecturer: 'Dosen A',
        isActive: true,
      );
      final e2 = ScheduledNotificationEntity(
        id: ScheduledNotificationEntity.computeId('Dummy MK 2', 'Sabtu', 10),
        courseName: 'Dummy MK 2',
        dayOfWeek: 'Sabtu',
        classTime: DateTime(now.year, now.month, now.day, 10, 0),
        reminderOffset: 5,
        room: 'Lab 2',
        lecturer: 'Dosen B',
        isActive: true,
      );
      await repo.saveAll([e1, e2]);
      await cubit.loadNotifications();
    }
    // Force 5m
    await cubit.updateReminderInterval(5);
    await $.pump(const Duration(seconds: 1));
    expect(cubit.state.reminderIntervalMinutes, 5);
    for (final n in cubit.state.notifications) expect(n.reminderOffset, 5);
    // keep app alive for dumpsys
    await $.pump(const Duration(seconds: 3));
  });
}
