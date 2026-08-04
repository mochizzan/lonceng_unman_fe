// Main entry point for Lonceng UnMan
// Initializes app with Material 3 theme and go_router navigation
// Based on DESIGN.md theme configuration (section 3.10)

import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/routes/app_router.dart';
import 'package:lonceng_unman_fe/core/auth/auth_status.dart';
import 'package:lonceng_unman_fe/core/services/fcm_service.dart';
import 'package:lonceng_unman_fe/core/theme/theme.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
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

/// Background message handler — must be top-level (not inside a class).
/// Registered before runApp() so it works even when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate (required before using FCM).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before using any Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register the background message handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM for foreground message handling.
  // Notification taps are handled by the router via GoRouter's redirect.
  await FcmService.instance.initialize(
    onNotificationTap: (message) {
      // Handle navigation based on message data type.
      // Example: if message.data['type'] == 'jadwal_update', navigate to jadwal.
      developer.log('Notification tap: ${message.data}', name: 'FCM');
    },
  );

  // Register dependencies
  Services.register<GetAuth>(
    GetAuth(AuthRepositoryImpl(remoteDataSource: StubAuthRemoteDataSource())),
  );
  Services.register<GetHome>(
    GetHome(HomeRepositoryImpl(remoteDataSource: StubHomeRemoteDataSource())),
  );
  Services.register<GetJadwal>(
    GetJadwal(
      JadwalRepositoryImpl(remoteDataSource: StubJadwalRemoteDataSource()),
    ),
  );
  Services.register<GetProfile>(
    GetProfile(
      ProfileRepositoryImpl(remoteDataSource: StubProfileRemoteDataSource()),
    ),
  );

  runApp(const LoncengUnmanApp());
}

class LoncengUnmanApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final authNotifier = authStatusNotifier ?? AuthStatusNotifier();
    final themeNotifierValue = themeNotifier ?? ThemeNotifier();

    final router = AppRouter.create(
      authStatusNotifier: authNotifier,
      themeNotifier: themeNotifierValue,
    );

    return MaterialApp.router(
      title: 'Lonceng UnMan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifierValue.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
