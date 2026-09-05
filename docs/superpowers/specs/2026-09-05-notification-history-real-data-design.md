# Desain: Riwayat Notifikasi Real Data (FCM + Pengingat Kelas Lokal)

- Tanggal: 2026-09-05
- Lokasi: `docs/superpowers/specs/2026-09-05-notification-history-real-data-design.md`
- Scope: FE-only (`lonceng_unman_fe`). Backend Go tidak diubah.
- Status: Disetujui per seksi 1/5 s/d 5/5 di sesi brainstorming (Pendekatan 2 — B Optimistic + Reconciliation ringan + Retensi C + isRead/dot).
- Terkait: `lib/features/notification/presentation/pages/notification_history_page.dart`, `lib/features/notification/presentation/cubit/notification_cubit.dart`, `lib/features/notification/presentation/cubit/notification_state.dart`, `lib/features/notification/domain/services/notification_scheduler.dart`, `lib/features/notification/domain/entities/notification_delivered_entity.dart`, `lib/features/notification/data/models/notification_delivered_model.dart`, `lib/features/notification/data/datasources/notification_delivered_local_data_source.dart`, `lib/features/notification/domain/repositories/notification_delivered_repository.dart`, `lib/features/notification/data/repositories/notification_delivered_repository_impl.dart`, `lib/core/services/notification_service.dart`, `lib/core/services/fcm_service.dart`, `lib/main.dart`, `lib/core/routes/app_router.dart`, `lib/features/home/presentation/widgets/home_header.dart`, `lib/features/settings/presentation/pages/settings_page.dart`, `lib/core/constants/notification_config.dart`, `lib/core/constants/app_strings.dart`.

## 1. Latar Belakang & Masalah

`NotificationHistoryPage` saat ini bukan riwayat. Ia `BlocBuilder<NotificationCubit>` dari `state.notifications` yang isinya `ScheduledNotificationEntity` dari Hive box `scheduled_notifications` (typeId 0) — daftar jadwal mingguan yang di-repeat OS via `flutter_local_notifications.zonedSchedule(matchDateTimeComponents: dayOfWeekAndTime)` — lengkap dengan `Switch` on/off per matkul. Label `Riwayat Notifikasi` menyesatkan; yang tampil adalah settingan.

Infra riwayat real sudah setengah jadi tapi mati:
- `NotificationDeliveredEntity/Model` (typeId 1), `NotificationDeliveredLocalDataSource` (box `notification_delivered`), `NotificationDeliveredRepository` + `NotificationDeliveredRepositoryImpl` sudah di-register di `main.dart` (Hive adapter typeId 1, 3 box: `scheduled_notifications`, `notification_settings`, `notification_delivered`), plus 8 unit test model/entity.
- Tidak ada satu pun `deliveredRepo.save()` dipanggil dari `NotificationService` / `FcmService` / `NotificationScheduler`. `NotificationService.onDidReceiveNotificationResponse` hanya forward ke `KhsDownloadNotificationController`, `FcmService.onForegroundMessage` expose stream tapi tidak dipersist.

Request: ubah halaman menjadi riwayat real yang menampilkan notifikasi yang pernah masuk — mencakup **FCM remote + pengingat kelas lokal**, tetap berfungsi walau app di-kill (alarm via AlarmManager), dengan `isRead` + dot di bell icon, retensi selamanya plus hapus all / swipe per item, tanpa menambah kode native Kotlin.

## 2. Tujuan & Non-Tujuan

### 2.1 Tujuan

1. `NotificationHistoryPage` menampilkan timeline kronologis riwayat real (lokal + FCM) — bukan settingan — dengan grouping `Hari ini / Kemarin / Minggu ini / Lebih lama`, newest first, filter `deliveredAt <= now` (future optimistic di-hide).
2. Pengingat kelas lokal memakai **B Optimistic**: saat `NotificationScheduler.schedule*()` dipanggil, langsung tulis 1 `NotificationDeliveredEntity(deliveredAt = tzTrigger)` per matkul ke `notification_delivered` (pure Dart, tanpa native).
3. Tambah **reconciliation ringan saat app dibuka** (pure Dart, tanpa Kotlin) agar history mingguan tak terbatas: `main()` + `AppLifecycleState.resumed` loop `scheduledBox` per `scheduledId`, bandingkan `lastTriggerLewat > max(deliveredAt)` lalu generate occurrence yang kelewat. Acuan = minggu terakhir (`max`), bukan pertama.
4. FCM memakai **true delivered**: listener `FcmService.onForegroundMessage` + `onMessageOpenedApp` + `getInitialMessage()` → `deliveredRepo.save(source:fcm, deliveredAt: DateTime.now())`.
5. Tiap item punya `isRead` + `source` (`classReminder|fcm`) + `scheduledId` link (untuk lokal) + `title/body` untuk FCM; dot merah di bell `HomeHeader` nyala kalau `unreadCount > 0`, hilang setelah buka Riwayat / tap item.
6. Retensi **C**: simpan selamanya, AppBar action `Hapus semua` (confirm dialog) + swipe `Dismissible` hapus per item.

### 2.2 Non-Tujuan

- Tidak menambah kode native Kotlin (`BroadcastReceiver`, `MethodChannel`, file bridge) — tetap pure Dart/Flutter.
- Tidak pre-generate N minggu (mis 12) — cukup 1 baris optimistic + reconciliation.
- Tidak mengubah `SettingsPage` toggle per-kelas (tetap dari `scheduledBox` lama + `Switch`).
- Tidak mengubah `NotificationChannel` enum / `NotificationConfig` channel / `NotificationLocalDataSource` scheduled / `Home/Jadwal/Profile` BLoC.
- Tidak menambah filter tab `Semua|Kelas|FCM` di iterasi pertama (single list gabung kronologis; tab bisa iterasi berikutnya).
- Tidak menambah backend endpoint / migrasi Hive di luar field baru `NotificationDelivered*`.

## 3. Keputusan yang Disetujui

| # | Pertanyaan | Keputusan |
|---|-----------|-----------|
| 1 | Sumber riwayat | **FCM + pengingat kelas lokal keduanya** digabung 1 timeline kronologis. |
| 2 | Mekanisme lokal | **B Optimistic** — tulis `deliveredAt = tzTrigger` saat `schedule*()` (future), di UI hide `> now`. Rekomendasi awal C, disetujui. |
| 3 | Pendekatan weekly repeat | **Pendekatan 2 — B + Reconciliation ringan saat app dibuka** (bukan B murni yang mandek 1 occurrence, bukan native). Acuan `max(deliveredAt)` per `scheduledId`. |
| 4 | Retensi | **C — simpan selamanya + Hapus semua + swipe per item.** `cancelSingle/deleteAll` scheduled tidak hapus delivered (audit trail). |
| 5 | isRead & dot | **Ada `isRead` per item**, `unreadCount = visible.where(!isRead).length`, dot di `HomeHeader` bell, `markAllRead()` saat buka HistoryPage + `markAsRead(id)` saat tap. |

## 4. Desain Rinci

### 4.1 Arsitektur (DISETUJUI)

Reuse feature `notification` Clean Architecture (`presentation → domain → data`), tidak bikin feature baru — reuse `NotificationCubit` yang sudah disediakan `ShellRoute` via `MultiBlocProvider(create: NotificationCubit..loadNotifications())` agar dot dan history share 1 instance.

```
Sebelum:
  NotificationHistoryPage → state.notifications (ScheduledEntity, Switch)
  NotificationCubit: loadNotifications/schedule*/toggle/updateInterval/cancelAll + markHistoryViewed(bool)
  NotificationScheduler._scheduleAlarm → zonedSchedule(weekly=true) (tanpa delivered write)
  FcmService.onForegroundMessage → _messageController.add (tidak persist)

Sesudah:
  NotificationHistoryPage → state.visibleDelivered (DeliveredEntity, tanpa Switch, grouping + unread hint + Dismissible)
  NotificationCubit: + delivered/visibleDelivered/unreadCount + loadDelivered/reconcileDelivered/markAsRead/markAllRead/deleteDelivered/deleteAllDelivered
  NotificationScheduler._scheduleAlarm → zonedSchedule + deliveredRepo.save(source:classReminder, isRead:false, deliveredAt:tzTrigger) [optimistic]
  FcmService wiring di main.dart: onForegroundMessage/onMessageOpenedApp/getInitialMessage → deliveredRepo.save(source:fcm, deliveredAt:now)
  main() + LoncengUnmanApp.didChangeAppLifecycleState(resumed) → cubit.reconcileDelivered()
  HomeHeader bell → Badge(isLabelVisible: unreadCount>0)
```

File map:

| Status | File | Keterangan |
|--------|------|------------|
| Ubah | `lib/features/notification/domain/entities/notification_delivered_entity.dart` | Tambah field `isRead: bool`, `source: NotificationSource`, `scheduledId: int?`, `title/body: String?` untuk FCM, equality/hash. |
| Ubah | `lib/features/notification/data/models/notification_delivered_model.dart` | HiveField baru untuk field di atas, `typeId: 1` tetap, `fromEntity/toEntity` update, regenerate `.g.dart`. |
| Ubah | `lib/features/notification/data/datasources/notification_delivered_local_data_source.dart` | Tambah `markAsRead(id)`, `markAllRead()`, `delete(id)`, `getUnreadCount()`, sudah ada `getAll()` sort desc + `getByDateRange`. |
| Ubah | `lib/features/notification/domain/repositories/notification_delivered_repository.dart` | Tambah method sama (kontrak). |
| Ubah | `lib/features/notification/data/repositories/notification_delivered_repository_impl.dart` | Implementasi mapping baru. |
| Ubah | `lib/features/notification/domain/services/notification_scheduler.dart` | Setelah `zonedSchedule()` tulis optimistic ke `deliveredRepo` (inject repo). |
| Ubah | `lib/features/notification/presentation/cubit/notification_cubit.dart` | Inject `NotificationDeliveredRepository`, state baru + method baru. |
| Ubah | `lib/features/notification/presentation/cubit/notification_state.dart` | Tambah `delivered`, getter `visibleDelivered` (filter `<=now` sort desc), `unreadCount`, `filterSource` opsional. |
| Ubah total | `lib/features/notification/presentation/pages/notification_history_page.dart` | Rewrite: grouping, `_DeliveredTile`, `Dismissible`, AppBar `Hapus semua`, `initState → markAllRead()`. |
| Ubah | `lib/features/home/presentation/widgets/home_header.dart` | Bell `Badge` dari `unreadCount`. |
| Ubah | `lib/main.dart` | Wiring FCM listeners → deliveredRepo, panggil `reconcileDelivered()` setelah Hive open + di `didChangeAppLifecycleState`. |
| Tambah (opsional) | `lib/features/notification/domain/entities/notification_source.dart` | Enum `NotificationSource { classReminder, fcm }` — prefer inline di `notification_delivered_entity.dart` untuk hindari file baru; jika inline maka tidak tambah file. |
| Tidak diubah | `lib/features/notification/data/datasources/notification_local_data_source.dart`, `lib/features/notification/data/repositories/notification_repository_impl.dart`, `lib/core/constants/notification_config.dart` (box names), `lib/features/settings/presentation/pages/settings_page.dart` | ScheduledBox & toggle tetap. |

ID strategy (agar weekly tidak overwrite):

- classReminder: `deliveredId = hash("${scheduledId}_${tzTrigger.millisecondsSinceEpoch}") & 0x7FFFFFFF`
- fcm: `deliveredId = hash("fcm_${message.messageId ?? now.millis}_${now.millis}") & 0x7FFFFFFF`
- `scheduledId` sendiri tetap `ScheduledNotificationEntity.computeId(course|day|hour)`.

### 4.2 Komponen & Data Flow (DISETUJUI)

**Model/Entity baru:**

```dart
enum NotificationSource { classReminder, fcm }

class NotificationDeliveredEntity {
  final int id; // per-occurrence, bukan per-scheduled
  final int? scheduledId; // non-null untuk classReminder
  final String courseName; // untuk fcm: title fallback
  final String dayOfWeek; // untuk fcm: "" atau format tanggal
  final DateTime classTime; // untuk fcm: now
  final DateTime deliveredAt; // classReminder: tzTrigger, fcm: now
  final String room;
  final String? lecturer;
  final String? title; // fcm title
  final String? body; // fcm body
  final NotificationSource source;
  final bool isRead;
}
```

HiveModel tambah `@HiveField(7) sourceIndex` (int, index enum `NotificationSource`), `@HiveField(8) isRead`, `@HiveField(9) scheduledId`, `@HiveField(10) title`, `@HiveField(11) body` — lanjut dari `0..6` yang sudah ada; `read` wajib fallback `fields[7] as int? ?? 0`, `fields[8] as bool? ?? false`, `fields[9] as int?`, `fields[10] as String?`, `fields[11] as String?` agar box lama (7 field) tidak pecah.

**NotificationLocalDataSource (delivered) — method baru:**

```dart
Future<void> markAsRead(int id) async {
  final m = _box.get(id); if (m == null) return;
  await _box.put(id, m.copyWith(isRead: true));
}
Future<void> markAllRead() async {
  for (final m in _box.values.where((m) => !m.isRead)) {
    await _box.put(m.id, m.copyWith(isRead: true));
  }
}
Future<void> delete(int id) => _box.delete(id);
int getUnreadCount() => _box.values.where((m) => !m.isRead && !m.deliveredAt.isAfter(DateTime.now())).length;
```

**Flow 1 — Optimistic write (saat alarm di-set):**

```
scheduleAllDays(items) / scheduleForDay(jadwal) / scheduleSingle(entity) / rescheduleAllWithNewOffset(newOffset)
  for each item/entity:
    tzTrigger = DayNameMapper.nextOccurrence(day) + classTime - Duration(minutes: offset) → tz.TZDateTime
    await notificationService.zonedSchedule(id: scheduledId, date: tzTrigger, matchDateTimeComponents: dayOfWeekAndTime, weekly:true)
    deliveredId = hash("${scheduledId}_${tzTrigger.millis}")
    if (!_box.containsKey(deliveredId))
      await deliveredRepo.save(DeliveredEntity(id: deliveredId, scheduledId: scheduledId, deliveredAt: tzTrigger, source: classReminder, isRead: false, ...))
  emit state.copyWith(delivered: await deliveredRepo.getAll(), unreadCount: visibleUnread)
```

`cancelSingle`/`deleteAll` scheduled tidak hapus delivered.

**Flow 2 — FCM true delivered (real-time):**

```dart
// di main() setelah Services.register<NotificationDeliveredRepository>
final deliveredRepo = Services.get<NotificationDeliveredRepository>();
FcmService.instance.onForegroundMessage.listen((msg) async {
  final now = DateTime.now();
  await deliveredRepo.save(NotificationDeliveredEntity(
    id: hash("fcm_${msg.messageId ?? now.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}"),
    scheduledId: null, source: NotificationSource.fcm, isRead: false,
    deliveredAt: now, title: msg.notification?.title, body: msg.notification?.body,
    courseName: msg.notification?.title ?? msg.notification?.body ?? "Notifikasi", dayOfWeek: "", classTime: now, room: "", lecturer: null,
  ));
  // optional: trigger cubit.loadDelivered() via Services.get<NotificationCubit>() jika sudah create
});
FcmService.instance.onMessageOpenedApp.listen(same);
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) same(initial);
```

**Flow 3 — Reconciliation (saat app dibuka, pure Dart, per scheduledId, acuan minggu terakhir):**

```
trigger: main() after Hive open + LoncengUnmanApp.didChangeAppLifecycleState(AppLifecycleState.resumed)

reconcileDelivered():
  now = DateTime.now()
  for scheduled in scheduledBox.values:
    scheduledId = scheduled.id
    tzTriggerNext = computeTrigger(scheduled) // DayNameMapper.nextOccurrence + time - offset → tz.TZDateTime
    lastTrigger = now.isBefore(tzTriggerNext) ? tzTriggerNext.subtract(7d) : tzTriggerNext
    deliveredForId = deliveredBox.values.where(scheduledId==id) sort by deliveredAt desc
    lastSaved = deliveredForId.firstOrNull?.deliveredAt
    cursor = lastSaved == null ? lastTrigger : lastSaved.add(Duration(days: 7))
    while (!cursor.isAfter(lastTrigger) && !cursor.isAfter(now)) {
      deliveredId = hash("${scheduledId}_${cursor.millis}")
      if (!box.containsKey(deliveredId))
        await deliveredRepo.save(...deliveredAt: cursor, isRead: false, source: classReminder)
      cursor = cursor.add(Duration(days: 7))
      if (cursor.isAfter(lastTrigger)) break
    }
  emit updated delivered + unreadCount
```

- Cap: weekly jadi max 1–3 iterasi per item (5 matkul × 3 minggu tidak buka = 15 write, aman).
- Future `tzTriggerNext > now` tidak ditulis di reconciliation — sudah ditulis optimistic di Flow 1, tapi hide di `visibleDelivered`.
- Timezone: `tz.local` yang sudah `initializeTimeZones()` di `NotificationService.initialize()`; fallback device time di `_scheduleAlarm` try/catch tetap.

**Flow 4 — Read & Delete (Retensi C):**

```
Buka HistoryPage → initState addPostFrameCallback → cubit.markAllRead() → deliveredRepo.markAllRead() → unreadCount=0 → dot hilang
Tap _DeliveredTile → cubit.markAsRead(id)
Swipe Dismissible(endToStart, background: delete) → cubit.deleteDelivered(id) → box.delete(id)
AppBar "Hapus semua" (enable jika visibleDelivered.isNotEmpty) → confirm AlertDialog → cubit.deleteAllDelivered() → box.clear()
```

**Filtering di state (bukan datasource):**

```dart
List<NotificationDeliveredEntity> get visibleDelivered =>
  delivered.where((d) => !d.deliveredAt.isAfter(DateTime.now())).toList()
    ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
int get unreadCount => visibleDelivered.where((d) => !d.isRead).length;
```

### 4.3 Error Handling & Edge Cases (DISETUJUI)

| Kasus | Handling | UI |
|-------|----------|----|
| `notification_delivered` Hive corruption | EH-3 di `main.dart` sudah: `deleteBoxFromDisk('notification_delivered')` + recreate → history kosong, tidak crash. | Empty state. |
| `scheduledBox` kosong (belum login / KRS kosong) | `reconcileDelivered()` no-op (loop kosong). | History empty. |
| `deliveredId` hash collision / duplikat | `box.containsKey(deliveredId)` check sebelum `put` (Flow 1 & 3). | Skip, tidak duplikat. |
| FCM `getToken` / `onMessage` throw | `catch` + `debugPrint`, tidak block UI (sama seperti `FcmService.initialize` timeout 10s). | History tidak nambah, app tetap jalan. |
| Permission ditolak | Optimistic tetap tulis (B), label `Perkiraan` opsional jika `canScheduleExactNotifications()==false`. Delivered lama tetap. | Tetap tampil, bukan error. |
| Timezone `tz.local` null | Fallback device `DateTime` (sudah ada di `_scheduleAlarm` try/catch). | Trigger tetap hitung. |
| Ganti `reminderOffset` | `rescheduleAllWithNewOffset` → `deleteAll` scheduled → `schedule*` lagi → delivered baru pakai `tzTrigger` baru, delivered lama tetap (audit trail C). | History akumulatif. |
| `toggleNotification(false)` | Tidak hapus delivered existing, cuma `cancelSingle` alarm. | History tetap. |
| 3 minggu tidak buka app | Reconciliation generate 3 baris sekaligus (loop while). | History nambah 3. |
| Future `deliveredAt > now` | Hide dari `visibleDelivered` dan tidak hitung `unreadCount`. | Tidak tampil sampai waktunya lewat. |
| Tap cepat 2× markAllRead | Idempotent (`if (!isRead) put`). | Aman. |
| `delivered` list besar (ratusan) | `ListView.separated` + grouping header, `Hive` box murah, tanpa pagination iterasi 1. | Scroll biasa. |

### 4.4 Testing & Acceptance Criteria (DISETUJUI)

| Layer | Skenario | Expected |
|-------|----------|----------|
| Unit Model | `fromEntity/toEntity` roundtrip dengan field baru `isRead/source/scheduledId/title/body` | Equality hold, null lecturer/title/body ok |
| Unit DataSource | `save` → `getAll` sort desc, `markAsRead`, `markAllRead`, `delete`, `getUnreadCount` filter `<=now` | Hand-written fake Box (tanpa mockito), ikut `test/helpers/test_di.dart` |
| Unit Reconcile | Per `scheduledId` max logic, future hide, dedup `containsKey`, 3 minggu generate 3 | Pure Dart test dengan fake scheduledBox + deliveredBox |
| Cubit blocTest | `loadDelivered` → `visibleDelivered` sorted + `unreadCount`, `markAllRead` → `unreadCount==0`, `deleteAllDelivered` → empty, FCM save → `source==fcm` | `FakeNotificationDeliveredRepository` |
| Widget HistoryPage | `visibleDelivered.isEmpty` → empty `Icons.notifications_none`, grouping `Hari ini/Kemarin/Minggu ini`, swipe delete → `Dismissible`, `Hapus semua` confirm → clear, tap tile → `markAsRead` | `test/features/notification/presentation/pages/notification_history_page_test.dart` update |
| Widget HomeHeader | `unreadCount>0` → `Badge` dot visible, `markAllRead` → dot hilang | `BlocBuilder` reuse cubit |
| Static | `flutter analyze --no-pub` (scope `lib/`) | 0 error |
| Manual | Fresh install → Login → `scheduleAllDays` → History tampil 1 per matkul future hide? → tunggu trigger lewat / ubah device time → `visibleDelivered` nambah, FCM console send → muncul `source:fcm`, buka History → dot hilang, swipe → hilang, `Hapus semua` → kosong | E2E manual |

Key: `Key('notification_history_page')`, `Key('delivered_tile_$id')`, `Key('delete_all_delivered')` — ganti `switch` key lama.

### 4.5 Risiko, File Map & Estimasi (DISETUJUI)

**Risiko & mitigasi:**

| Risiko | Mitigasi |
|--------|----------|
| Hive typeId 1 field baru pecah `read` lama (field missing) | `NotificationDeliveredModelAdapter.read` pakai `fields[7] as int? ?? 0`, `fields[8] as bool? ?? false`, `fields[9] as int?`, `fields[10/11] as String?` fallback (lihat §4.2). |
| `deliveredId` per-occurrence beda dengan `ScheduledId` → `getById` lama tidak relevan | `deliveredBox` pakai `deliveredId` baru; `scheduledId` simpan terpisah sebagai FK, tidak pakai `getById(scheduledId)`. |
| Weekly `tzTrigger` hitung beda dengan `_scheduleAlarm` (drift) | Ekstrak `computeTrigger(ScheduledNotificationEntity)` shared helper di `notification_scheduler.dart` (atau util `day_name_mapper.dart` wrapper) dipakai scheduler + reconciliation — bukan file baru. |
| FCM `messageId` null → hash collision | Fallback `now.millisecondsSinceEpoch` (sudah di Flow 2) — cukup, tanpa random. |
| `flutter analyze` / `build_runner` gagal setelah HiveField baru | `dart run build_runner build --delete-conflicting-outputs` untuk regen `notification_delivered_model.g.dart`. |

**File map final (ringkas):**

| Status | File |
|--------|------|
| Ubah | `lib/features/notification/domain/entities/notification_delivered_entity.dart` |
| Ubah | `lib/features/notification/data/models/notification_delivered_model.dart` + `.g.dart` (regen) |
| Ubah | `lib/features/notification/data/datasources/notification_delivered_local_data_source.dart` |
| Ubah | `lib/features/notification/domain/repositories/notification_delivered_repository.dart` |
| Ubah | `lib/features/notification/data/repositories/notification_delivered_repository_impl.dart` |
| Ubah | `lib/features/notification/domain/services/notification_scheduler.dart` |
| Ubah | `lib/features/notification/presentation/cubit/notification_cubit.dart` |
| Ubah | `lib/features/notification/presentation/cubit/notification_state.dart` |
| Ubah total | `lib/features/notification/presentation/pages/notification_history_page.dart` |
| Ubah | `lib/features/home/presentation/widgets/home_header.dart` |
| Ubah | `lib/main.dart` |
| Tambah | `lib/features/notification/domain/entities/notification_source.dart` (atau inline) |
| Tidak diubah | `notification_local_data_source.dart`, `notification_repository_impl.dart`, `notification_config.dart`, `settings_page.dart` |

**Estimasi implementasi (untuk writing-plans):**

- Fase 1: Entity/Model + HiveAdapter regen + DataSource/Repository method baru.
- Fase 2: `NotificationScheduler` optimistic write + `NotificationCubit` state/method baru + `FcmService` wiring di `main.dart` + `reconcileDelivered`.
- Fase 3: `NotificationHistoryPage` rewrite + `HomeHeader` badge.
- Fase 4: `flutter analyze` + `build_runner` + unit/cubit/widget test update + manual E2E.

## 5. Pertanyaan Terbuka

Tidak ada. Semua keputusan (FCM+lokal, B Optimistic, Reconciliation per `max` minggu terakhir, Retensi C, `isRead`+dot) disetujui per seksi 1/5 s/d 5/5. Tradeoff B murni yang mandek 1 occurrence diterima dan ditambal reconciliation (Pendekatan 2).

## 6. Self-Review

- Placeholder/TBD: tidak ada.
- Kontradiksi internal: tidak ada — optimistic future hide konsisten dengan reconciliation `<=now`; `cancelSingle` tidak hapus delivered konsisten dengan Retensi C audit trail.
- Scope: fokus — 11 ubah + 1 tambah + 4 tidak diubah; pure Dart tanpa native, tanpa backend.
- Ambiguitas: `deliveredId` per-occurrence vs `scheduledId` FK dipisah eksplisit; `visibleDelivered` filter `!isAfter(now)` eksplisit; `isRead` default `false`.
