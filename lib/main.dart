// Main entry point for Lonceng UnMan
// Initializes app with Material 3 theme and go_router navigation
// Based on DESIGN.md theme configuration (section 3.10)

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/network/api_client.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/firebase_options.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/data/repositories/home_repository_impl.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/data/repositories/krs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/khs/data/repositories/khs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/repositories/data_initialization_repository_impl.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/core/services/notification_scheduler_noop.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Background message handler — must be top-level (not inside a class).
/// Registered before runApp() so it works even when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate (required before using FCM).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError: ${details.exceptionAsString()}',
      name: 'ErrorHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase before using any Firebase services.
      bool firebaseReady = false;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (e) {
        developer.log(
          'Firebase init failed, running without FCM: $e',
          name: 'main',
        );
      }

      if (firebaseReady) {
        // Register the background message handler.
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Initialize FCM for foreground message handling.
        // Notification taps are handled by the router via GoRouter's redirect.
        await FcmService.instance.initialize(
          onNotificationTap: (message) {
            // Handle navigation based on message data type.
            // Example: if message.data['type'] == 'jadwal_update', navigate to jadwal.
            developer.log('Notification tap: ${message.data}', name: 'FCM');
          },
        );
      }

      // ── Hive local persistence (with corruption recovery, EH-3) ──
      // Store Hive boxes in external cache so data survives app updates
      // and can be inspected via adb shell.
      // Target: emulated/0/Android/data/<package>/cache/
      // path_provider doesn't expose getExternalCacheDir, so we derive
      // it from getExternalStorageDirectory (…/files/) → replace with /cache/.
      String? hivePath;
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          hivePath = externalDir.path.replaceAll('/files', '/cache');
          // Ensure the cache directory exists
          final cacheDir = Directory(hivePath);
          if (!await cacheDir.exists()) {
            await cacheDir.create(recursive: true);
          }
          developer.log('Hive path: $hivePath', name: 'main');
        }
      } catch (e) {
        developer.log(
          'External cache dir unavailable, using default: $e',
          name: 'main',
        );
      }

      late Box<ScheduledNotificationModel> notificationsBox;
      late Box<int> settingsBox;
      try {
        if (hivePath != null) {
          await Hive.initFlutter(hivePath);
        } else {
          await Hive.initFlutter();
        }
        Hive.registerAdapter(ScheduledNotificationModelAdapter());
        notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
          NotificationConfig.scheduledNotificationsBox,
        );
        settingsBox = await Hive.openBox<int>(
          NotificationConfig.notificationSettingsBox,
        );
      } catch (e) {
        developer.log(
          'Hive init failed, attempting corruption recovery: $e',
          name: 'main',
        );
        // Best-effort cleanup of corrupted boxes before retrying
        try {
          if (hivePath != null) {
            await Hive.initFlutter(hivePath);
          } else {
            await Hive.initFlutter();
          }
          await Hive.deleteBoxFromDisk(
            NotificationConfig.scheduledNotificationsBox,
          );
          await Hive.deleteBoxFromDisk(
            NotificationConfig.notificationSettingsBox,
          );
        } catch (_) {
          // Ignore — fresh start if disk cleanup also fails
        }
        Hive.registerAdapter(ScheduledNotificationModelAdapter());
        notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
          NotificationConfig.scheduledNotificationsBox,
        );
        settingsBox = await Hive.openBox<int>(
          NotificationConfig.notificationSettingsBox,
        );
      }

      // ── Onboarding local data source ──
      final onboardingDataSource = OnboardingLocalDataSource();
      await onboardingDataSource.init();
      Services.register<OnboardingLocalDataSource>(onboardingDataSource);
      Services.register<OnboardingRepository>(
        OnboardingRepositoryImpl(onboardingDataSource),
      );

      // ── Notification local data source ──
      Services.register<NotificationLocalDataSource>(
        NotificationLocalDataSource(
          notificationsBox: notificationsBox,
          settingsBox: settingsBox,
        ),
      );

      // ── NotificationService (with error handling, EH-4) ──
      final notificationService = NotificationService();
      Services.register<NotificationService>(notificationService);
      var notificationServiceReady = false;
      try {
        await notificationService.initialize();
        notificationServiceReady = true;
      } catch (e) {
        developer.log(
          'NotificationService init failed, local alarms disabled: $e',
          name: 'main',
        );
      }

      // ── Notification repository ──
      Services.register<NotificationRepository>(
        NotificationRepositoryImpl(
          localDataSource: Services.get<NotificationLocalDataSource>(),
        ),
      );

      // ── Notification scheduler (only when platform alarms are available) ──
      if (notificationServiceReady) {
        Services.register<NotificationScheduler>(
          NotificationScheduler(
            repository: Services.get<NotificationRepository>(),
            notificationService: Services.get<NotificationService>(),
          ),
        );
      } else {
        // Register no-op fallback to prevent StateError on all main routes
        Services.register<NotificationScheduler>(NotificationSchedulerNoop());
      }

      // ── Academic Cache Service ──
      final academicCacheService = AcademicCacheService();
      await academicCacheService.initialize();
      Services.register<AcademicCacheService>(academicCacheService);

      // ── Theme Notifier (global, drives theme mode) ──
      final themeNotifier = ThemeNotifier();
      Services.register<ThemeNotifier>(themeNotifier);

      // ── Auth Status Notifier (global, drives router redirect) ──
      final authStatusNotifier = AuthStatusNotifier();
      Services.register<AuthStatusNotifier>(authStatusNotifier);

      // ── API Client (with 401→logout wiring) ──
      final apiClient = ApiClient(
        baseUrl: AppStrings.apiBaseUrl,
        onAuthError: () async {
          // Await logout so cache is cleared before redirect.
          await Services.performFullLogout();
        },
      );
      Services.register<ApiClient>(apiClient);

      // ── Auth (real HTTP) ──
      final authDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      Services.register<AuthRemoteDataSource>(authDataSource);
      Services.register<GetAuth>(
        GetAuth(AuthRepositoryImpl(remoteDataSource: authDataSource)),
      );
      // ── KRS ──
      final krsDataSource = KrsRemoteDataSourceImpl(
        apiClient: apiClient,
        academicCacheService: academicCacheService,
      );
      Services.register<KrsRemoteDataSource>(krsDataSource);
      final getKrs = GetKrs(KrsRepositoryImpl(remoteDataSource: krsDataSource));
      Services.register<GetKrs>(getKrs);

      // ── KHS ──
      final khsDataSource = KhsRemoteDataSourceImpl(
        apiClient: apiClient,
        academicCacheService: academicCacheService,
      );
      Services.register<KhsRemoteDataSource>(khsDataSource);
      final getKhs = GetKhs(KhsRepositoryImpl(remoteDataSource: khsDataSource));
      Services.register<GetKhs>(getKhs);

      // ── Data Initialization (KRS + KHS pipeline) ──
      final dataInitDataSource = DataInitializationRemoteDataSource(
        getKrs: getKrs,
        getKhs: getKhs,
        academicCacheService: academicCacheService,
      );
      Services.register<DataInitializationRemoteDataSource>(dataInitDataSource);
      Services.register<GetDataInitialization>(
        GetDataInitialization(
          DataInitializationRepositoryImpl(
            remoteDataSource: dataInitDataSource,
          ),
        ),
      );

      // ── Home (real KRS/KHS data) ──
      Services.register<GetHome>(
        GetHome(
          HomeRepositoryImpl(
            remoteDataSource: HomeRemoteDataSourceImpl(
              academicCacheService: academicCacheService,
            ),
          ),
        ),
      );

      // ── Jadwal (real KRS data) ──
      Services.register<GetJadwal>(
        GetJadwal(
          JadwalRepositoryImpl(
            remoteDataSource: JadwalRemoteDataSourceImpl(
              krsDataSource: krsDataSource,
              academicCacheService: academicCacheService,
            ),
          ),
        ),
      );

      // ── Profile (real KRS/KHS data) ──
      Services.register<GetProfile>(
        GetProfile(
          ProfileRepositoryImpl(
            remoteDataSource: ProfileRemoteDataSourceImpl(
              academicCacheService: academicCacheService,
              apiClient: apiClient,
            ),
          ),
        ),
      );

      // Set auth status to unknown while we validate credentials
      authStatusNotifier.setStatus(AuthStatus.unknown);

      // Credential validation on app restart
      final cache = Services.get<AcademicCacheService>();
      final credentials = await cache.loadCredentials();

      if (credentials != null &&
          credentials['npm'] != null &&
          credentials['npm']!.isNotEmpty &&
          credentials['password'] != null &&
          credentials['password']!.isNotEmpty) {
        // Credentials exist — try to validate via login API
        try {
          final getAuth = Services.get<GetAuth>();
          await getAuth(
            npm: credentials['npm']!,
            password: credentials['password']!,
          );
          // Login succeeded — check if data exists in cache
          final hasKrs = cache.hasKrsData(npm: credentials['npm']!);
          final hasKhsList = cache.hasKhsList(npm: credentials['npm']!);

          if (hasKrs && hasKhsList) {
            // Creds + data → authenticated, go to home
            authStatusNotifier.setStatus(AuthStatus.authenticated);
          } else {
            // Creds + no data → unauthenticated, login page runs data-init
            authStatusNotifier.setStatus(AuthStatus.unauthenticated);
          }
        } catch (e) {
          // Network error or invalid creds → clear creds, go to login
          developer.log('Credential validation failed: $e', name: 'main');
          await cache.clearCredentials();
          authStatusNotifier.setStatus(AuthStatus.unauthenticated);
        }
      } else {
        // No credentials → go to login
        authStatusNotifier.setStatus(AuthStatus.unauthenticated);
      }

      runApp(const LoncengUnmanApp());
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught error: $error',
        name: 'ErrorHandler',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

class LoncengUnmanApp extends StatefulWidget {
  const LoncengUnmanApp({
    super.key,
    this.authStatusNotifier,
    this.themeNotifier,
  });

  /// Injected for testing. When null, a new [AuthStatusNotifier] is created.
  final AuthStatusNotifier? authStatusNotifier;

  /// Injected for testing. When null, a new [ThemeNotifier] is created.
  final ThemeNotifier? themeNotifier;

  @override
  State<LoncengUnmanApp> createState() => _LoncengUnmanAppState();
}

class _LoncengUnmanAppState extends State<LoncengUnmanApp> {
  late final AuthStatusNotifier _authNotifier;
  late final ThemeNotifier _themeNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authNotifier =
        widget.authStatusNotifier ?? Services.get<AuthStatusNotifier>();
    _themeNotifier = widget.themeNotifier ?? Services.get<ThemeNotifier>();
    _router = AppRouter.create(
      authStatusNotifier: _authNotifier,
      themeNotifier: _themeNotifier,
    );
  }

  @override
  void dispose() {
    // Only dispose if we created it (not injected)
    if (widget.authStatusNotifier == null) {
      _authNotifier.dispose();
    }
    // DI-registered ThemeNotifier lifecycle is managed by DI; don't dispose it.
    // Only dispose an injected (test) instance.
    if (widget.themeNotifier != null) {
      _themeNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DataInitBloc(Services.get<GetDataInitialization>()),
      child: ListenableBuilder(
        listenable: _themeNotifier,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Lonceng UnMan',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: _themeNotifier.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
