# Task 1: Fix Dark Mode SecondaryContainer Color

**File to modify:** `lib/core/theme/app_theme.dart:dark_colorScheme`

**Context:**
- This task fixes the critical theme violation: dark mode `secondaryContainer` currently set to `#5D460A` but DESIGN.md tables 3.2-3.3 specify `#FFC340`
- Align dark mode secondaryContainer with DESIGN.md spec

**Imports:**
- None needed

**Global Constraints:**
- All colors MUST use `Theme.of(context).colorScheme` or `ThemeExtension<AppColors>()` — NO hex literals
- `app_theme.dart` must define `secondaryContainer.light = #FFDB92`, `secondaryContainer.dark = #FFC340`

**Implementation Steps:**
1. Open `lib/core/theme/app_theme.dart`
2. Locate `darkColorScheme` static method
3. Locate `secondaryContainer` assignment (currently `#5D460A`)
4. Replace with: `secondaryContainer: Color(0xFFFFC340)`
5. Verify `lightColorScheme.secondaryContainer` still `#FFDB92`
6. Run: `flutter analyze lib/core/theme/app_theme.dart` → 0 errors
7. Commit message: `fix(theme): set dark secondaryContainer to #FFC340 per DESIGN.md`

**Deliverable:** File modified, analysis clean, 1 commit

**Report-file path:** `docs/superpowers/plans/task-1-report.md`

**Self-review checklist:**
- [ ] Dark mode secondaryContainer is `#FFC340`
- [ ] Light mode secondaryContainer still `#FFDB92`
- [ ] No unused imports
- [ ] `flutter analyze` clean
- [ ] Good commit message

**Testing:**
- `flutter analyze lib/core/theme/app_theme.dart` → expected 0 errors
- Mental check: no upcoming diffs that would break imports

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED