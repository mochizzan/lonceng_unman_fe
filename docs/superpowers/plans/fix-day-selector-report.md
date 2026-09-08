# Fix: Day Selector Pill Colors

## Status: ✅ DONE

## Summary

The day selector pill in `jadwal_day_selector.dart` was using `cs.primaryContainer` / `cs.onPrimaryContainer` for the selected state. Per DESIGN.md §5.3, chips/pills must use `secondaryContainer` / `onSecondaryContainer`. Fixed both the color references and the file header comment.

## Changes

| File | Change |
|------|--------|
| `lib/features/jadwal/presentation/widgets/jadwal_day_selector.dart:39` | `cs.primaryContainer` → `cs.secondaryContainer` |
| `lib/features/jadwal/presentation/widgets/jadwal_day_selector.dart:42` | `cs.onPrimaryContainer` → `cs.onSecondaryContainer` |
| `lib/features/jadwal/presentation/widgets/jadwal_day_selector.dart:4` | Comment updated to match |

## Commit

```
da92738 fix(theme): change day selector pill to secondaryContainer per DESIGN.md
```

## Test Results

```
flutter analyze lib/features/jadwal/presentation/widgets/jadwal_day_selector.dart
→ No issues found! (ran in 1.1s)
```

## Self-Review

- **Scope:** Only the day selector pill was affected. Verified `jadwal_card.dart` uses `primaryContainer` for *cards* (not chips) — correct per DESIGN.md.
- **Comment accuracy:** Header comment at line 4 now correctly documents `secondaryContainer / onSecondaryContainer`.
- **Behavioral correctness:** Selected pill gets `secondaryContainer` background + `onSecondaryContainer` text. Unselected pill retains `surfaceContainerHighest` + `onSurfaceVariant` + `outlineVariant` border — unchanged.
- **Border logic preserved:** Selected state still sets border color to `bgColor` (now `secondaryContainer`) with width 0 — pill looks filled without a visible border. Correct.
- **No regressions:** `flutter analyze` passes clean. No other widgets in the jadwal feature are affected.
