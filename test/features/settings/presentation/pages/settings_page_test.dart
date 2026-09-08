// test/features/settings/presentation/pages/settings_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/core/domain/schedule_entity.dart';
import 'package:lonceng_unman_fe/core/theme/theme_notifier.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
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

  testWidgets(
    'notification list renders with toggles when notifications exist',
    (WidgetTester tester) async {
      final themeNotifier = ThemeNotifier();
      final cubit = _FakeNotificationCubit(
        initialState: NotificationState(
          status: NotificationStatus.loaded,
          notifications: [
            ScheduledNotificationEntity(
              id: 1,
              courseName: 'Algoritma',
              dayOfWeek: 'Senin',
              classTime: DateTime(2026, 1, 1, 8, 0),
              reminderOffset: 5,
              room: 'R.301',
              isActive: true,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: SettingsPage(notifier: themeNotifier),
          ),
        ),
      );

      expect(find.text('NOTIFIKASI KELAS'), findsOneWidget);
      expect(find.text('Algoritma'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    },
  );
}

/// Fake cubit for testing — avoids requiring real dependencies.
class _FakeNotificationCubit extends Cubit<NotificationState>
    implements NotificationCubit {
  _FakeNotificationCubit({NotificationState? initialState})
    : super(initialState ?? const NotificationState());

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> scheduleFromJadwal(JadwalEntity jadwal) async {}

  @override
  Future<void> scheduleAll(List<ScheduleItemEntity> items) async {}

  @override
  Future<void> toggleNotification(int id) async {}

  @override
  Future<void> updateReminderInterval(int minutes) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> checkPermission() async => true;

  @override
  void markHistoryViewed() {}

  @override
  Future<void> deleteAllDelivered() async {}

  @override
  Future<void> deleteDelivered(int id) async {}

  @override
  Future<void> loadDelivered() async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markAsRead(int id) async {}

  @override
  Future<void> reconcileDelivered() async {}
}
