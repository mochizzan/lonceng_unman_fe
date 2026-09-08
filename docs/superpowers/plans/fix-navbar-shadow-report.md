# Fix Navbar Shadow Hex Report

## Summary
Replaced the hardcoded `Color(0x40000000)` hex literal in `FloatingNavBar` with the theme-aware `Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25)`, eliminating the last runtime hex literal in `main_shell_scaffold.dart`.

## What Changed
- **File:** `lib/core/routes/main_shell_scaffold.dart` (line 103)
- **Before:** `color: Color(0x40000000)` (hardcoded hex literal — violates "NO hex literals in runtime code" constraint)
- **After:** `color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25)`
- **Semantic equivalence:** `ColorScheme.shadow` is `Color(0xFF000000)` (opaque black) in both light and dark themes; `.withValues(alpha: 0.25)` reproduces the original 25% opacity. Visual behavior is identical.

## Note on AppColors vs ColorScheme
The original fix specification referenced `AppColors.shadow`, but `shadow` is a standard `ColorScheme` property, not part of the custom `AppColors` extension. `ColorScheme.shadow` was used instead — this is the idiomatic Flutter source for shadow color.

## Commits
| Hash | Message |
|------|---------|
| `06b23a3` | `fix(theme): replace navbar shadow hex with colorScheme.shadow` |

## Analysis Results
```
flutter analyze lib/core/routes/main_shell_scaffold.dart
→ No issues found! (ran in 1.5s)
```

## Self-Review
- **Correctness:** The `BoxShadow.color` now resolves from the active `ColorScheme` at runtime. Since `ColorScheme.shadow` is `Color(0xFF000000)` in both light and dark themes in this project, the rendered shadow is pixel-identical to the original hardcoded value.
- **Constraint compliance:** Zero `Color(0x...)` hex literals remain in `main_shell_scaffold.dart` (verified via regex grep).
- **No `const` loss:** The `const` qualifier was correctly removed from the `BoxShadow` list since the color is now computed at runtime from `Theme.of(context)`.
- **No functional change:** The visual output is unchanged; the fix is purely structural/convention-driven.
- **Scope:** Single line changed in a single file. No other files affected; no API changes.
