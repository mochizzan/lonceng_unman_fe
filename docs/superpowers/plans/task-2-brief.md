# Task 2: Replace Navbar Hardcode Constants with AppColor References

**File to modify:** `lib/core/routes/main_shell_scaffold.dart:15-60`

**Context:**
- Task 1 fixed `app_theme.dart` dark mode colors
- Task 2 eliminates hardcoded navbar hex constants, replacing them with `Theme.of(context).appColors.navbarSurface/navbarActivePill/onNavBarSurface/onNavBarActivePill`
- Navbar needs to use theme colors instead of local const

**Imports:**
- Add: `import 'package:lonceng_unman_fe/core/theme/app_theme.dart';`

**Global Constraints:**
- All colors MUST use `Theme.of(context).colorScheme` or `ThemeExtension<AppColors>()`
- navbarSurface = `#201B11` (from AppColors.light)
- navbarActivePill = `#FFC107` (from AppColors.light)
- onNavBarSurface = `#F9F0EB`?
- onNavBarActivePill = `#181309`?
- InactiveBgColor = `#FBEFDE` replaced with `Theme.of(context).colorScheme.surfaceContainerHighest`
- IconColor = `#402D00` replaced with `Theme.of(context).appColors.onNavBarSurface`

**Implementation Steps:**
1. Open `lib/core/routes/main_shell_scaffold.dart`
2. Identify Navbar hardcoded constants around lines 15-60:
   - `const Color navSurfaceColor = 0x201B11`
   - `const Color navActivePillColor = 0xFFC107`
   - `const Color navInactiveBgColor = 0xFBEFDE`
   - `const Color navIconColor = 0x402D00`
3. Add import: `import 'package:lonceng_unman_fe/core/theme/app_theme.dart';`
4. Replace these constants with theme references:
   - `navSurfaceColor` → `Theme.of(context).appColors.navbarSurface`
   - `navActivePillColor` → `Theme.of(context).appColors.navbarActivePill`
   - `navInactiveBgColor` → `Theme.of(context).colorScheme.surfaceContainerHighest`
   - `navIconColor` → `Theme.of(context).appColors.onNavBarSurface`
5. Delete the const declarations for these colors (they're now inline)
6. Verify no remaining hardcoded navbar colors
7. Run: `flutter analyze lib/core/routes/main_shell_scaffold.dart` → 0 errors
8. Commit message: `fix(theme): replace navbar hardcode constants with AppColors refs`

**Deliverables:**
- Modified `lib/core/routes/main_shell_scaffold.dart` (no const colors, all theme refs)
- Analysis clean
- Commit in history

**Report-file path:** `docs/superpowers/plans/task-2-report.md`

**Self-review checklist:**
- [ ] No hardcoded navbar colors remain
- [ ] All navbar colors use `Theme.of(context).appColors.navbarSurface/navbarActivePill/onNavBarSurface/onNavBarActivePill`
- [ ] Inactive background uses `colorScheme.surfaceContainerHighest`
- [ ] No imports or code purely decorative deleted
- [ ] `flutter analyze` clean
- [ ] Commit message matches pattern

**Testing:**
- `flutter analyze lib/core/routes/main_shell_scaffold.dart` → expected 0 errors
- No resulting color changes visible (values should be identical, just via theme)

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED