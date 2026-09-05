// Main entry point for Lonceng UnMan
// Initializes app with Material 3 theme and go_router navigation
// Based on DESIGN.md theme configuration (section 3.10)

import 'dart:async';
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
import 'package:lonceng_unman_fe/core/cache/avatar_cache_service.dart';
import 'package:lonceng_unman_fe/core/cache/bio_cache_service.dart';
import 'package:lonceng_unman_fe/core/widgets/navbar_visibility_notifier.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/utils/delivered_id.dart';
import 'package:lonceng_unman_fe/firebase_options.dart';
import 'package:lonceng_unman_fe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/get_auth.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/load_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/auth/domain/usecases/save_auth_credentials.dart';
import 'package:lonceng_unman_fe/features/home/data/datasources/home_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/home/data/repositories/home_repository_impl.dart';
import 'package:lonceng_unman_fe/features/home/domain/usecases/get_home.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/usecases/get_jadwal.dart';
import 'package:lonceng_unman_fe/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:lonceng_unman_fe/features/profile/domain/usecases/get_profile.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/photo_service.dart';
import 'package:lonceng_unman_fe/features/krs/domain/usecases/get_krs.dart';
import 'package:lonceng_unman_fe/features/krs/data/datasources/krs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/krs/data/repositories/krs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/khs/domain/usecases/get_khs.dart';
import 'package:lonceng_unman_fe/features/khs/data/datasources/khs_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/khs/data/repositories/khs_repository_impl.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_pdf_service.dart';
import 'package:lonceng_unman_fe/features/khs/data/services/khs_download_notification_controller.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/datasources/data_initialization_remote_data_source.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/services/pull_refresh_debounce.dart';
import 'package:lonceng_unman_fe/features/data_initialization/data/repositories/data_initialization_repository_impl.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/usecases/get_data_initialization.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/student_profile/data/datasources/student_profile_remote_data_source.dart';
import 'package:lonceng_unman_fe/core/cache/student_profile_cache_service.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';
import 'package:lonceng_unman_fe/features/notification/domain/services/notification_scheduler.dart';
import 'package:lonceng_unman_fe/core/services/notification_scheduler_noop.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';
import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_delivered_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/repositories/notification_delivered_repository_impl.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:lonceng_unman_fe/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:lonceng_unman_fe/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lonceng_unman_fe/core/network/connectivity_service.dart';
import 'package:lonceng_unman_fe/features/connectivity/cubit/connectivity_cubit.dart';

/// Background message handler — must be top-level (not inside a class).
/// Registered before runApp() so it works even when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM-BG] Background handler triggered!');
  debugPrint('[FCM-BG]   Message ID: ${message.messageId}');
  debugPrint('[FCM-BG]   Title: ${message.notification?.title}');
  debugPrint('[FCM-BG]   Body: ${message.notification?.body}');
  debugPrint('[FCM-BG]   Data: ${message.data}');
  // Initialize Firebase in background isolate (required before using FCM).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM-BG] Firebase initialized in background isolate');
}

Future<void> main() async {
  // Run ALL initialization inside runZonedGuarded for error isolation.
  // Both ensureInitialized() and runApp() MUST be in the same zone
  // to satisfy Flutter's debugCheckZone assertion.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Global error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint(
          '[ErrorHandler] FlutterError: ${details.exceptionAsString()}'
          '\n${details.stack}',
        );
      };

      // Initialize Firebase before using any Firebase services.
      debugPrint('[MAIN] Initializing Firebase...');
      bool firebaseReady = false;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
        debugPrint('[MAIN] Firebase initialized SUCCESSFULLY');
      } catch (e) {
        debugPrint('[MAIN] Firebase init FAILED: $e');
      }

      if (firebaseReady) {
        // Register the background message handler.
        debugPrint('[MAIN] Registering background message handler...');
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        debugPrint('[MAIN] Background handler registered');

        // Initialize FCM for foreground message handling.
        // Fire-and-forget with timeout to prevent blocking runApp().
        debugPrint('[MAIN] Initializing FcmService...');
        FcmService.instance
            .initialize(
              onNotificationTap: (message) {
                debugPrint('[FCM] Notification tap: ${message.data}');
              },
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint(
                  '[MAIN] FCM init TIMED OUT (10s), continuing without FCM',
                );
              },
            )
            .catchError((e) {
              debugPrint('[MAIN] FCM init FAILED: $e');
            });
      } else {
        debugPrint('[MAIN] Firebase not ready, skipping FCM setup');
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
          debugPrint('[MAIN] Hive path: $hivePath');
        }
      } catch (e) {
        debugPrint('[MAIN] External cache dir unavailable, using default: $e');
      }

      late Box<ScheduledNotificationModel> notificationsBox;
      late Box<int> settingsBox;
      late Box<NotificationDeliveredModel> deliveredBox;
      try {
        if (hivePath != null) {
          await Hive.initFlutter(hivePath);
        } else {
          await Hive.initFlutter();
        }
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(ScheduledNotificationModelAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(NotificationDeliveredModelAdapter());
        }
        notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
          NotificationConfig.scheduledNotificationsBox,
        );
        settingsBox = await Hive.openBox<int>(
          NotificationConfig.notificationSettingsBox,
        );
        deliveredBox = await Hive.openBox<NotificationDeliveredModel>(
          'notification_delivered',
        );
      } catch (e) {
        debugPrint(
          '[MAIN] Hive init failed, attempting corruption recovery: $e',
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
          await Hive.deleteBoxFromDisk('notification_delivered');
        } catch (_) {
          // Ignore — fresh start if disk cleanup also fails
        }
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(ScheduledNotificationModelAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(NotificationDeliveredModelAdapter());
        }
        notificationsBox = await Hive.openBox<ScheduledNotificationModel>(
          NotificationConfig.scheduledNotificationsBox,
        );
        settingsBox = await Hive.openBox<int>(
          NotificationConfig.notificationSettingsBox,
        );
        deliveredBox = await Hive.openBox<NotificationDeliveredModel>(
          'notification_delivered',
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
        debugPrint(
          '[MAIN] NotificationService init failed, local alarms disabled: $e',
        );
      }

      // ── KHS Download Notification Controller (decoupled) ──
      // Wires notification tap actions (open/share/retry) via NotificationService.
      try {
        final downloadController = KhsDownloadNotificationController(
          notificationService: Services.get<NotificationService>(),
        );
        Services.register<KhsDownloadNotificationController>(
          downloadController,
        );
        Services.get<NotificationService>().setExternalResponseHandler(
          downloadController.handleResponse,
        );
      } catch (e) {
        debugPrint('[MAIN] Download controller register failed: $e');
      }

      // ── Notification repository ──
      Services.register<NotificationRepository>(
        NotificationRepositoryImpl(
          localDataSource: Services.get<NotificationLocalDataSource>(),
        ),
      );

      // ── Notification delivered tracking ──
      Services.register<NotificationDeliveredLocalDataSource>(
        NotificationDeliveredLocalDataSource(box: deliveredBox),
      );
      Services.register<NotificationDeliveredRepository>(
        NotificationDeliveredRepositoryImpl(
          localDataSource: Services.get<NotificationDeliveredLocalDataSource>(),
        ),
      );

      // ── Notification scheduler (only when platform alarms are available) ──
      if (notificationServiceReady) {
        Services.register<NotificationScheduler>(
          NotificationScheduler(
            repository: Services.get<NotificationRepository>(),
            notificationService: Services.get<NotificationService>(),
            deliveredRepository:
                Services.get<NotificationDeliveredRepository>(),
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

      // ── Bio Cache Service (box `bioBox`, per-NPM, cleared on logout) ──
      final bioCacheService = BioCacheService();
      await bioCacheService.initialize();
      Services.register<BioCacheService>(bioCacheService);

      // ── Avatar Cache Service (box `avatar`, per-NPM, tahan logout) ──
      final avatarCacheService = AvatarCacheService();
      await avatarCacheService.initialize();
      Services.register<AvatarCacheService>(avatarCacheService);

      // ── Photo Service (fetch foto dari backend LMS) ──
      final photoService = PhotoService();
      Services.register<PhotoService>(photoService);

      // ── Avatar Cubit (singleton global) ──
      // Satu instance dipakai bersama oleh header Home dan halaman Profile
      // agar foto yang tampil selalu identik. bootstrap() membaca NPM dari
      // kredensial tersimpan tanpa memblokir startup.
      final avatarCubit = AvatarCubit(
        cache: avatarCacheService,
        academicCache: academicCacheService,
        photoService: photoService,
      );
      Services.register<AvatarCubit>(avatarCubit);
      unawaited(avatarCubit.bootstrap());

      // ── Theme Notifier (global, drives theme mode) ──
      final themeNotifier = ThemeNotifier();
      Services.register<ThemeNotifier>(themeNotifier);

      // ── Auth Status Notifier (global, drives router redirect) ──
      final authStatusNotifier = AuthStatusNotifier();
      Services.register<AuthStatusNotifier>(authStatusNotifier);

      // ── Connectivity Service (singleton — wrapped plugin, consumed by
      //    ConnectivityCubit at the root, LoginPage, and DataInitBloc) ──
      Services.register<ConnectivityService>(
        ConnectivityServiceImpl(Connectivity()),
      );

      // ── Navbar Visibility Notifier (global, controls navbar during modals) ──
      Services.register<NavbarVisibilityNotifier>(NavbarVisibilityNotifier());

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
      Services.register<SaveAuthCredentials>(
        SaveAuthCredentials(academicCacheService),
      );
      Services.register<LoadAuthCredentials>(
        LoadAuthCredentials(academicCacheService),
      );

      // ── Student Profile (profile scrape + confirmation flow) ──
      final studentProfileCacheService = StudentProfileCacheService();
      await studentProfileCacheService.initialize();
      Services.register<StudentProfileCacheService>(studentProfileCacheService);
      Services.register<StudentProfileRemoteDataSource>(
        StudentProfileRemoteDataSourceImpl(
          apiClient: apiClient,
          cacheService: studentProfileCacheService,
        ),
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

      // ── KHS PDF Service ──
      Services.register<KhsPdfService>(KhsPdfService());

      // ── Data Initialization (Profile + KRS + KHS + Photo pipeline) ──
      // PullRefreshDebounce singleton WAJIB terdaftar sebelum
      // DataInitializationRemoteDataSource dikonstruksi karena constructor
      // memakai fallback `debounce ?? Services.get<PullRefreshDebounce>()`.
      Services.register<PullRefreshDebounce>(PullRefreshDebounce());
      final dataInitDataSource = DataInitializationRemoteDataSource(
        getKrs: getKrs,
        getKhs: getKhs,
        profileDataSource: Services.get<StudentProfileRemoteDataSource>(),
        photoService: photoService,
        avatarCache: avatarCacheService,
        debounce: Services.get<PullRefreshDebounce>(),
      );
      Services.register<DataInitializationRemoteDataSource>(dataInitDataSource);
      Services.register<GetDataInitialization>(
        GetDataInitialization(
          DataInitializationRepositoryImpl(
            remoteDataSource: dataInitDataSource,
          ),
        ),
      );

      // ── Home (real KRS/KHS data + StudentProfile) ──
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

      // ── Jadwal (real KRS data + StudentProfile) ──
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

      // ── Profile (real KRS/KHS data + StudentProfile) ──
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

      // ── FCM → delivered history wiring (pure Dart) ──
      _wireFcmDelivered();

      // Reconcile delivered history on cold start (also runs on resume in didChangeAppLifecycleState).
      try {
        final deliveredRepo = Services.get<NotificationDeliveredRepository>();
        final scheduler = Services.get<NotificationScheduler>();
        final scheduledRepo = Services.get<NotificationRepository>();
        unawaited(
          _reconcileDelivered(
            deliveredRepo,
            scheduler,
            scheduledRepo,
          ).catchError((e) {
            debugPrint('[MAIN] Cold-start reconcile failed: $e');
          }),
        );
      } catch (e) {
        debugPrint('[MAIN] Cold-start reconcile skipped: $e');
      }

      // Validate credentials locally (no backend call) to avoid blocking runApp().
      final cache = Services.get<AcademicCacheService>();
      final credentials = await cache.loadCredentials();

      if (credentials != null &&
          credentials['npm'] != null &&
          credentials['npm']!.isNotEmpty &&
          credentials['password'] != null &&
          credentials['password']!.isNotEmpty) {
        final hasKrs = cache.hasKrsData(npm: credentials['npm']!);
        final hasKhsList = cache.hasKhsList(npm: credentials['npm']!);

        if (hasKrs && hasKhsList) {
          authStatusNotifier.setStatus(AuthStatus.authenticated);
        } else {
          authStatusNotifier.setStatus(AuthStatus.unauthenticated);
        }
      } else {
        authStatusNotifier.setStatus(AuthStatus.unauthenticated);
      }

      runApp(const LoncengUnmanApp());
    },
    (error, stackTrace) {
      debugPrint('[ERROR] Uncaught error in runZonedGuarded: $error');
      debugPrint('[ERROR] Stack: $stackTrace');
    },
  );
}

void _wireFcmDelivered() {
  try {
    final deliveredRepo = Services.get<NotificationDeliveredRepository>();
    Future<void> saveFcm(RemoteMessage msg) async {
      final now = DateTime.now();
      final id =
          'fcm_${msg.messageId ?? now.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}'
              .hashCode &
          0x7FFFFFFF;
      if (deliveredRepo.containsKey(id)) return;
      try {
        await deliveredRepo.save(
          NotificationDeliveredEntity(
            id: id,
            courseName:
                msg.notification?.title ??
                msg.notification?.body ??
                'Notifikasi',
            dayOfWeek: '',
            classTime: now,
            deliveredAt: now,
            room: '',
            lecturer: null,
            isRead: false,
            source: NotificationSource.fcm,
            title: msg.notification?.title,
            body: msg.notification?.body,
          ),
        );
      } catch (e) {
        debugPrint('[FCM-DELIVERED] save failed: $e');
      }
    }

    FcmService.instance.onForegroundMessage.listen(saveFcm);
    FcmService.instance.onMessageOpenedApp.listen(saveFcm);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) saveFcm(msg);
    });
    debugPrint('[MAIN] FCM delivered wiring OK');
  } catch (e) {
    debugPrint('[MAIN] FCM delivered wiring skipped: $e');
  }
}

Future<void> _reconcileDelivered(
  NotificationDeliveredRepository deliveredRepo,
  NotificationScheduler scheduler,
  NotificationRepository scheduledRepo,
) async {
  final scheduled = await scheduledRepo.getAll();
  if (scheduled.isEmpty) return;
  final deliveredAll = await deliveredRepo.getAll();
  final now = DateTime.now();
  for (final s in scheduled) {
    if (!s.isActive) continue;
    final tzTrigger = scheduler.computeTrigger(s);
    final triggerDt = DateTime(
      tzTrigger.year,
      tzTrigger.month,
      tzTrigger.day,
      tzTrigger.hour,
      tzTrigger.minute,
    );
    final lastTrigger = now.isBefore(triggerDt)
        ? triggerDt.subtract(const Duration(days: 7))
        : triggerDt;
    final forId = deliveredAll.where((d) => d.scheduledId == s.id).toList()
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    final lastSaved = forId.isEmpty ? null : forId.first.deliveredAt;
    // Legacy 7-field rows have scheduledId==null — ignored for grouping to avoid duplicate
    DateTime cursor = lastSaved == null
        ? lastTrigger
        : lastSaved.add(const Duration(days: 7));
    while (!cursor.isAfter(lastTrigger) && !cursor.isAfter(now)) {
      final deliveredId = deliveredIdFor(s.id, cursor);
      if (!deliveredRepo.containsKey(deliveredId)) {
        await deliveredRepo.save(
          NotificationDeliveredEntity(
            id: deliveredId,
            courseName: s.courseName,
            dayOfWeek: s.dayOfWeek,
            classTime: s.classTime,
            deliveredAt: cursor,
            room: s.room,
            lecturer: s.lecturer,
            isRead: false,
            source: NotificationSource.classReminder,
            scheduledId: s.id,
          ),
        );
      }
      final next = cursor.add(const Duration(days: 7));
      if (next.isAfter(lastTrigger)) break;
      cursor = next;
    }
  }
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

class _LoncengUnmanAppState extends State<LoncengUnmanApp>
    with WidgetsBindingObserver {
  late final AuthStatusNotifier _authNotifier;
  late final ThemeNotifier _themeNotifier;
  late final GoRouter _router;

  /// Instance singleton dari DI — siklus hidupnya dikelola DI, jadi TIDAK
  /// ditutup oleh widget ini.
  late final AvatarCubit _avatarCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authNotifier =
        widget.authStatusNotifier ?? Services.get<AuthStatusNotifier>();
    _themeNotifier = widget.themeNotifier ?? Services.get<ThemeNotifier>();
    _avatarCubit = Services.get<AvatarCubit>();
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
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[LIFECYCLE] App resumed — refreshing connectivity');
      try {
        Services.get<ConnectivityService>().refresh();
      } catch (e) {
        debugPrint('[LIFECYCLE] Connectivity refresh failed: $e');
      }
      // Reconciliation for weekly delivered history
      try {
        final repo = Services.get<NotificationDeliveredRepository>();
        final scheduler = Services.get<NotificationScheduler>();
        final scheduledRepo = Services.get<NotificationRepository>();
        // Fire-and-forget: reuse cubit logic without needing cubit instance
        _reconcileDelivered(repo, scheduler, scheduledRepo);
      } catch (e) {
        debugPrint('[LIFECYCLE] reconcileDelivered failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(Services.get<ConnectivityService>()),
        ),
        BlocProvider(
          create: (_) => DataInitBloc(Services.get<GetDataInitialization>()),
        ),
        // AvatarCubit singleton milik DI — dipakai bersama header Home dan
        // halaman Profile. Memakai .value agar tidak ditutup oleh widget ini.
        BlocProvider<AvatarCubit>.value(value: _avatarCubit),
      ],
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
