# Theme Migration Plan

## Goal
Clean up theme files and fix remaining hardcoded colors. Remove dead code.

## Current State
| File | Status | Action |
|------|--------|--------|
| `lib/core/theme/app_theme.dart` | ACTIVE | KEEP |
| `lib/core/theme/theme.dart` | DEAD CODE | DELETE |
| `lib/core/theme/barrel.dart` | Active | Update if needed |
| `lib/shared/theme/app_colors.dart` | Empty placeholder | DELETE |

## Tasks

### Task M1: Delete Dead Theme Files
**Files to delete:**
- `lib/core/theme/theme.dart` (390 lines, dead code)
- `lib/shared/theme/app_colors.dart` (empty placeholder)

**Files to update:**
- `lib/shared/theme/barrel.dart` — remove app_colors.dart export if present

### Task M2: Add Success Color to AppColors
**File:** `lib/core/theme/app_theme.dart`

**Current AppColors:**
```dart
class AppColors extends ThemeExtension<AppColors> {
  final Color navbarSurface;
  final Color onNavbarSurface;
  final Color navbarActivePill;
  final Color onNavbarActivePill;
  final Color shadow;
  final Color success;
  // ... lerp, copyWith, etc.
}
```

**Issue:** `success` color already exists in AppColors! The hardcoded fallback in today_schedule.dart is redundant.

**Fix:** Remove the hardcoded fallback in today_schedule.dart and use only `appColors.success`.

### Task M3: Fix Hardcoded Shadow in bell_logo.dart
**File:** `lib/shared/widgets/bell_logo.dart`

**Change:**
```dart
// Before
BoxShadow(
  color: Color(0x0F000000),  // hardcoded black 6%
  blurRadius: 20,
  offset: const Offset(0, 4),
)

// After
BoxShadow(
  color: cs.shadow.withValues(alpha: 0.06),  // theme-derived
  blurRadius: 20,
  offset: const Offset(0, 4),
)
```

### Task M4: Verify All .withValues(alpha:) Usage
All 38 instances are already correct (theme-derived colors with alpha). No changes needed.

### Task M5: Verify Colors.transparent Usage
All 5 instances are intentional (navbar background). No changes needed.

## Execution Order
1. Task M1: Delete dead files
2. Task M2: Verify success color (no change needed if already in AppColors)
3. Task M3: Fix bell_logo.dart shadow
4. Task M4-M5: Verification only

## Verification
- `flutter analyze` passes
- No hardcoded Color(0x...) remaining in lib/
- All theme imports point to app_theme.dart
- barrel.dart exports correct files
