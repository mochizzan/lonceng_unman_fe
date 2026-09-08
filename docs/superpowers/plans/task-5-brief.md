# Task 5: Replace Hardcoded Shadow Opacity with colorScheme

**Files to modify:**
- `lib/features/auth/presentation/pages/login_page.dart:shadow`
- Scan and fix all other files with hardcoded custom shadow opacity values

**Context:**
- Replace hardcoded shadow alpha values with theme-based references
- Ensure shadow opacity consistent with design specs
- Focus on cards with custom shadows (stats, timeline, bio) and login page

**Global Constraints:**
- Replace hardcoded shadow opacity (e.g., `withValues(alpha: 0.??)`) with:
  - `Theme.of(context).colorScheme.shadow` for general shadows
  - `Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)` for border shadows
- Use standard alpha values (0.5, 0.6, 0.7) consistent with DESIGN.md

**Implementation Steps:**
1. Find all hardcoded shadow opacities:
   - Command: `grep -rn "withValues(alpha: 0\.[0-9])" lib/features/ --include="*.dart" | grep -v "comment"`
   - Identify files with hardcoded shadow alphas
   - Flag files: login_page.dart, stats cards, timeline cards, bio cards
2. Refactor Login Page Shadow:
   - Open `lib/features/auth/presentation/pages/login_page.dart`
   - Locate shadow using `BoxShadow(color: .outline.withValues(alpha: 0.??), ...)`
   - Replace with: `BoxShadow(color: .outlineVariant.withValues(alpha: 0.5), blurRadius: 20, offset: Offset(0, 8))` (or existing radius/offset values)
3. Fix Stats/Timeline/Bio Cards Shadows (if found):
   - Scan flagged card widgets for shadow patterns
   - Replace `BoxShadow(...color: .withValues(alpha: .??)...)` with `Theme.of(context).colorScheme.shadow` where logical
   - If card has intentional custom shadow, document rationale
4. Verify Shadow Consistency:
   - Run: `flutter analyze lib/features/auth/presentation/pages/login_page.dart`
   - Manually verify: open app, check shadow opacity visually consistent with design
5. Commit: `refactor(theme): replace hardcoded shadow opacity with colorScheme.shadow`

**Deliverables:**
- Modified files with theme-based shadows
- Analysis clean
- Commit in history

**Report-file path:** `docs/superpowers/plans/task-5-report.md`

**Self-review checklist:**
- [ ] No hardcoded shadow opacity values remain outside shadow[06]
- [ ] Shadow values use colorScheme or outlineVariant
- [ ] Shadow opacity consistent across components
- [ ] Analysis clean
- [ ] Commit message matches pattern

**Testing:**
- `flutter analyze` on modified files → expected 0 errors
- Visual spot-check: shadow opacity consistent with design

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED