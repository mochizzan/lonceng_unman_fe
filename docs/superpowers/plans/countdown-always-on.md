# Countdown Always-On — Implementation Plan

## Goal
Refactor `HeroCountdownCard` so the countdown timer is always visible when any upcoming class exists in the schedule — even if the next class is days away. The card should auto-transition to the next class when the current one ends, show countup for ongoing classes, and display contextual labels.

## Design Decisions (Locked)
1. **Layout**: Countdown big on top, "Tidak ada kelas hari ini" subtitle when no class today
2. **Ongoing**: Countup timer (elapsed time since class started) + "Sudah berjalan sejak" label
3. **Indicator label**: 3 states — upcoming/cross-day → "Kelas berikutnya dalam" (default dot), ongoing → "Sudah berjalan sejak" (green dot)
4. **Context text**: Dynamic — "Tidak ada kelas hari ini — 2 hari lagi (Selasa)"
5. **CTA button**: Contextual label — ≤6h → "Lihat Materi Kelas", >6h → "Lihat Jadwal Lengkap"
6. **Empty schedule**: Keep empty state (no countdown when no classes at all)
7. **Auto-transition**: Local logic in widget, switch next class when current ends (no BLoC re-fetch)
8. **CTA threshold**: 6 hours

## Files to Modify

### 1. `lib/core/constants/app_strings.dart` — Add new strings
```
homeClassOngoingLabel = 'Sudah berjalan sejak'
homeNoClassTodayPrefix = 'Tidak ada kelas hari ini —'
homeViewSchedule = 'Lihat Jadwal Lengkap'
homeDaysAway = 'hari lagi'
homeTomorrow = 'besok'
```

### 2. `lib/features/home/presentation/widgets/hero_countdown_card.dart` — Major refactor
**New parameters:**
- `List<ScheduleItemEntity> scheduleItems` — all today's schedule items for auto-transition

**New logic:**
- `_findNextFromSchedule()` — given current time, find the next upcoming or ongoing class from `scheduleItems`
- `_computeDisplayState()` — determine: is it upcoming, ongoing, or no-class-today?
- Timer callback: check if current class has ended → call `_findNextFromSchedule()` to switch
- Ongoing countup: `now.difference(startTime)` instead of `startTime.difference(now)`
- Context text builder: compute days/hours remaining, format dynamic text
- CTA label builder: if remaining ≤ 6h → "Lihat Materi Kelas", else → "Lihat Jadwal Lengkap"

**Key methods to add/modify:**
- `_getDisplayData()` — returns a record with: countdown Duration, label text, dot color, context text, isOngoing flag
- `_startTimer()` — modified to handle both countdown and countup modes
- `build()` — restructured to always show card (unless truly empty schedule)

### 3. `lib/features/home/presentation/pages/home_page.dart` — Minor change
Pass `data.scheduleItems` to `HeroCountdownCard`:
```dart
HeroCountdownCard(
  nextClass: data.nextClass,
  scheduleItems: data.scheduleItems,  // NEW
),
```

## Auto-Transition Algorithm
```
Every 1 second (existing Timer.periodic):
  1. if current nextClass is null → find next from scheduleItems
  2. if now > nextClass.endTime:
     a. Find next class from scheduleItems where startTime > now
     b. If found → update _currentNextClass, restart timer
     c. If not found → set _currentNextClass = null (show empty or keep showing last?)
  3. Recompute display state (countdown vs countup)
  4. setState
```

## Acceptance Criteria
- [ ] Countdown always shows when any upcoming class exists in schedule
- [ ] Shows "Tidak ada kelas hari ini" subtitle when no class today but next class is in future
- [ ] Ongoing classes show countup (elapsed time) with green pulsing dot
- [ ] Auto-transitions to next class when current ends (no manual refresh)
- [ ] CTA button shows "Lihat Materi" (≤6h) or "Lihat Jadwal Lengkap" (>6h)
- [ ] Empty schedule (no KRS data) still shows empty state
- [ ] `flutter analyze` passes with no errors
