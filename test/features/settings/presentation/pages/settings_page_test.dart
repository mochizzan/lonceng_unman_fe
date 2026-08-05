// test/features/settings/presentation/pages/settings_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:lonceng_unman_fe/features/notification/presentation/cubit/notification_state.dart';
import 'package:lonceng_unman_fe/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('SettingsPage renders appBar with title and settings items', (
    WidgetTester tester,
  ) async {
    final themeNotifier = ThemeNotifier();
    final cubit = _FakeNotificationCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationCubit>.value(
          value: cubit,
          child: SettingsPage(notifier: themeNotifier),
        ),
      ),
    );

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Tema Aplikasi'), findsOneWidget);
    expect(find.text('Ingatkan Sebelum Kelas'), findsOneWidget);
    expect(find.text('Versi Aplikasi'), findsOneWidget);
  });
}

/// Fake cubit for testing — avoids requiring real dependencies.
/// Method calls throw UnimplementedError (test should never invoke them).
class _FakeNotificationCubit extends Cubit<NotificationState>
    implements NotificationCubit {
  _FakeNotificationCubit() : super(const NotificationState());

  @override
  Future<void> loadNotifications() async => throw UnimplementedError('fake');

  @override
  Future<void> scheduleFromJadwal(JadwalEntity jadwal) async =>
      throw UnimplementedError('fake');

  @override
  Future<void> toggleNotification(int id) async =>
      throw UnimplementedError('fake');

  @override
  Future<void> updateReminderInterval(int minutes) async =>
      throw UnimplementedError('fake');

  @override
  Future<void> cancelAll() async => throw UnimplementedError('fake');

  @override
  Future<bool> checkPermission() async => true;
}
