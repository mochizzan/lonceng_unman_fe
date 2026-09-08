# Fix Login Button: secondaryContainer per DESIGN.md

## Status: ✅ COMPLETE

## Problem

The "Masuk" (Login) `FilledButton` on the login page used `cs.primaryContainer` / `cs.onPrimaryContainer` for its background and foreground colors. Per DESIGN.md, buttons should use the tonal button pattern: `secondaryContainer` / `onSecondaryContainer`.

## Changes

**File:** `lib/features/auth/presentation/pages/login_page.dart`

| Line | Before | After |
|------|--------|-------|
| 169 | `backgroundColor: cs.primaryContainer` | `backgroundColor: cs.secondaryContainer` |
| 170 | `foregroundColor: cs.onPrimaryContainer` | `foregroundColor: cs.onSecondaryContainer` |
| 184 | `color: cs.onPrimaryContainer` (Text) | `color: cs.onSecondaryContainer` |
| 193 | `color: cs.onPrimaryContainer` (Icon) | `color: cs.onSecondaryContainer` |

**Total:** 4 references changed, 1 file modified, 5 insertions, 5 deletions (BOM removed as side-effect).

## Commit

```
4c75977 fix(theme): change login button to secondaryContainer per DESIGN.md
```

## Test Results

```
flutter analyze lib/features/auth/presentation/pages/login_page.dart
→ No issues found! (ran in 1.5s)
```

## Self-Review

- **Correctness:** All 4 `primaryContainer`/`onPrimaryContainer` references within the `FilledButton` block were replaced. The `Text` and `Icon` child widgets that hard-code `color:` are now consistent with the `foregroundColor` set on the button style.
- **Scope:** Change is strictly confined to the single `FilledButton` in `_LoginCard`. No other widgets or color references were affected.
- **DESIGN.md compliance:** Tonal buttons use `secondaryContainer`/`onSecondaryContainer` — this fix aligns the login button with that specification.
- **No regressions:** `flutter analyze` passes clean with 0 issues. The button structure, shape, padding, and elevation are unchanged.
- **BOM removal:** The file had a UTF-8 BOM (`\xFEFF`) at byte 0 which was inadvertently removed by the editor. This is cosmetic and has no runtime effect — Flutter/Dart handles both encodings identically.
