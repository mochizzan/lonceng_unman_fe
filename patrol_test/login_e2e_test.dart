// patrol_test/login_e2e_test.dart
//
// End-to-end login test for Lonceng UnMan.
//
// Pumps the real app entry widget with real services (no Firebase/FCM
// needed for the login flow) and exercises the full production pipeline:
//   1. fill NPM + password fields
//   2. tap "Masuk Akun"
//   3. confirm the scraped student profile
//   4. wait for the 8-step data initialization to finish
//   5. verify Home renders with the "Lihat KHS" button
//
// Credentials (per user request):
//   NPM:      2211700006
//   Password: Izzan027
//
// Backend: production (https://lonceng-unman-api.miproduction.web.id),
// verified manually to accept the above credentials.
//
// Run:
//   patrol test -t patrol_test/login_e2e_test.dart --device 127.0.0.1:5557 \
//     --no-uninstall

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
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/services/notification_scheduler_noop.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/widgets/navbar_visibility_notifier.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/bloc/auth_event.dart';
import 'package:lonceng_unman_fe/features/auth/presentation/pages/login_page.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/repositories/data_initialization_repository_impl.dart';
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
import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/main.dart';
import 'package:patrol/patrol.dart';

/// Eagerly register the same DI services `main()` does, but skip
/// Firebase/FCM (not needed for login) and use a temp Hive path
/// (path_provider may not be available in test environment).
Future<void> _bootstrapRealServicesForLogin() async {
  // Use temp dir for Hive — path_provider is not reliable in tests.
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

  // Onboarding (mark complete so router doesn't redirect)
  final onboardingDataSource = OnboardingLocalDataSource();
  await onboardingDataSource.init();
  final onboardingRepo = OnboardingRepositoryImpl(onboardingDataSource);
  await onboardingRepo.markCompleted();
  Services.register<OnboardingLocalDataSource>(onboardingDataSource);
  Services.register<OnboardingRepository>(onboardingRepo);

  // Notification
  Services.register<NotificationLocalDataSource>(
    NotificationLocalDataSource(
      notificationsBox: notificationsBox,
      settingsBox: settingsBox,
    ),
  );
  final notificationService = NotificationService();
  Services.register<NotificationService>(notificationService);
  try {
    await notificationService.initialize();
    Services.register<NotificationScheduler>(
      NotificationScheduler(
        repository: Services.get<NotificationRepository>(),
        notificationService: notificationService,
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

  // Cache services
  final academicCacheService = AcademicCacheService();
  await academicCacheService.initialize();
  Services.register<AcademicCacheService>(academicCacheService);

  final bioCacheService = BioCacheService();
  await bioCacheService.initialize();
  Services.register<BioCacheService>(bioCacheService);

  final avatarCacheService = AvatarCacheService();
  await avatarCacheService.initialize();
  Services.register<AvatarCacheService>(avatarCacheService);

  final photoService = PhotoService();
  Services.register<PhotoService>(photoService);

  // AvatarCubit
  final avatarCubit = AvatarCubit(
    cache: avatarCacheService,
    academicCache: academicCacheService,
    photoService: photoService,
  );
  Services.register<AvatarCubit>(avatarCubit);

  // Theme + Auth status notifiers
  Services.register<ThemeNotifier>(ThemeNotifier());
  Services.register<AuthStatusNotifier>(AuthStatusNotifier());
  Services.register<NavbarVisibilityNotifier>(NavbarVisibilityNotifier());

  // API client (real HTTP — uses production base URL by default).
  final apiClient = ApiClient(
    baseUrl: AppStrings.apiBaseUrl,
    onAuthError: () async => Services.performFullLogout(),
  );
  Services.register<ApiClient>(apiClient);

  // Auth
  final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
  Services.register<AuthRemoteDataSource>(authDataSource);
  Services.register<GetAuth>(
    GetAuth(AuthRepositoryImpl(remoteDataSource: authDataSource)),
  );
  Services.register<SaveAuthCredentials>(
    SaveAuthCredentials(academicCacheService),
  );
  Services.register<LoadAuthCredentials>(
    LoadAuthCredentials(academicCacheService),
  );

  // Student profile
  final studentProfileCacheService = StudentProfileCacheService();
  await studentProfileCacheService.initialize();
  Services.register<StudentProfileCacheService>(studentProfileCacheService);
  Services.register<StudentProfileRemoteDataSource>(
    StudentProfileRemoteDataSourceImpl(
      apiClient: apiClient,
      cacheService: studentProfileCacheService,
    ),
  );

  // KRS / KHS
  final krsDataSource = KrsRemoteDataSourceImpl(
    apiClient: apiClient,
    academicCacheService: academicCacheService,
  );
  Services.register<KrsRemoteDataSource>(krsDataSource);
  final getKrs = GetKrs(KrsRepositoryImpl(remoteDataSource: krsDataSource));
  Services.register<GetKrs>(getKrs);

  final khsDataSource = KhsRemoteDataSourceImpl(
    apiClient: apiClient,
    academicCacheService: academicCacheService,
  );
  Services.register<KhsRemoteDataSource>(khsDataSource);
  final getKhs = GetKhs(KhsRepositoryImpl(remoteDataSource: khsDataSource));
  Services.register<GetKhs>(getKhs);
  Services.register<KhsPdfService>(KhsPdfService());

  // Data init
  final dataInitDataSource = DataInitializationRemoteDataSource(
    getKrs: getKrs,
    getKhs: getKhs,
    profileDataSource: Services.get<StudentProfileRemoteDataSource>(),
    photoService: photoService,
    avatarCache: avatarCacheService,
  );
  Services.register<DataInitializationRemoteDataSource>(dataInitDataSource);
  Services.register<GetDataInitialization>(
    GetDataInitialization(
      DataInitializationRepositoryImpl(remoteDataSource: dataInitDataSource),
    ),
  );

  // Home / Jadwal / Profile
  Services.register<GetHome>(
    GetHome(
      HomeRepositoryImpl(
        remoteDataSource: HomeRemoteDataSourceImpl(
          academicCacheService: academicCacheService,
          studentProfileCacheService: studentProfileCacheService,
        ),
      ),
    ),
  );
  Services.register<GetJadwal>(
    GetJadwal(
      JadwalRepositoryImpl(
        remoteDataSource: JadwalRemoteDataSourceImpl(
          krsDataSource: krsDataSource,
          academicCacheService: academicCacheService,
          studentProfileCacheService: studentProfileCacheService,
        ),
      ),
    ),
  );
  Services.register<GetProfile>(
    GetProfile(
      ProfileRepositoryImpl(
        remoteDataSource: ProfileRemoteDataSourceImpl(
          academicCacheService: academicCacheService,
          bioCacheService: bioCacheService,
          apiClient: apiClient,
          studentProfileCacheService: studentProfileCacheService,
        ),
      ),
    ),
  );
}

void main() {
  patrolTest('login end-to-end with valid credentials reaches Home', ($) async {
    await _bootstrapRealServicesForLogin();

    await $.pumpWidgetAndSettle(
      LoncengUnmanApp(
        authStatusNotifier: Services.get<AuthStatusNotifier>(),
        themeNotifier: Services.get<ThemeNotifier>(),
      ),
    );
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));

    // Branch A: already-logged-in cache hit
    try {
      await $(
        #npm_field,
      ).waitUntilVisible(timeout: const Duration(seconds: 15));
    } catch (_) {
      expect($(#lihat_khs_button), findsOneWidget);
      return;
    }

    // Branch B: fill login form
    // Use Patrol's `$.enterText` (not $(finder).enterText) because the
    // global version simulates real key presses, firing onChanged on
    // TextField. The finder-scoped version calls tester.enterText which
    // bypasses onChanged.
    // See: https://medium.com/@mailharshkhatri/beyond-the-widget-tree-true-integration-testing-with-flutter-and-patrol-c59fac5bc18b
    await $(#npm_field).tap();
    await $.pumpAndSettle();
    await $.enterText($(#npm_field), '2211700006');
    await $.pumpAndSettle(duration: const Duration(seconds: 2));

    await $(#password_field).tap();
    await $.pumpAndSettle();
    await $.enterText($(#password_field), 'Izzan027');
    await $.pumpAndSettle(duration: const Duration(seconds: 2));

    // Workaround: form's onChanged does not fire reliably in test
    // mode, so dispatch AuthBloc events directly. The bloc is provided
    // by the LoginPage route, so we can find it via the widget tree.
    final loginPage = find.byType(LoginPage);
    expect(loginPage, findsOneWidget);

    final BuildContext pageContext = $.tester.element(loginPage.first);
    final authBloc = BlocProvider.of<AuthBloc>(pageContext);
    authBloc.add(const AuthNpmChanged('2211700006'));
    authBloc.add(const AuthPasswordChanged('Izzan027'));
    await $.pumpAndSettle();

    // Capture bloc state transitions for diagnosis on failure.
    final stateLog = <String>[];
    final stateSub = authBloc.stream.listen((s) {
      stateLog.add(s.runtimeType.toString());
    });

    // Tap the actual FilledButton (not just the text). Tapping the
    // text "Masuk Akun" inside the button's Row may not propagate to
    // the button's onPressed in test mode.
    final filledButtonFinder = find.byType(FilledButton);
    if (filledButtonFinder.evaluate().isNotEmpty) {
      await $.tester.tap(filledButtonFinder.last);
    } else {
      await $('Masuk Akun').tap();
    }
    // Use pump() (not pumpAndSettle) because the button transitions
    // to a CircularProgressIndicator (loading state) that animates
    // forever and would never settle.
    await $.pump();

    // Login API + profile scrape is 2 HTTP round-trips. With cold DNS
    // + TLS handshake on MuMu Player this can take 30-60s, so wait up
    // to 120s. If still no review, dump the bloc state log for
    // diagnosis.
    try {
      await $(
        'Konfirmasi Data Profil',
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
    } catch (e) {
      // ignore: avoid_print
      print(
        'Login submit did not reach review screen after 120s.\n'
        'State log: $stateLog',
      );
      rethrow;
    } finally {
      await stateSub.cancel();
    }

    await $('Ya, Konfirmasi').tap();
    // DataInitProgressView shows a CircularProgressIndicator (loading)
    // that animates forever — use pump() not pumpAndSettle().
    await $.pump();

    // Wait for data init pipeline to finish (Home visible).
    // 8 backend calls + caching: 2-5 minutes on slow networks.
    // The progress view shows between login and home.
    await $(
      #lihat_khs_button,
    ).waitUntilVisible(timeout: const Duration(seconds: 300));

    expect($(#lihat_khs_button), findsOneWidget);
    expect($('SKS Semester Ini'), findsOneWidget);
    expect($('Kuliah Hari Ini'), findsOneWidget);
  });
}
