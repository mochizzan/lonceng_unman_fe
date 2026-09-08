# Task 4: Limit PrimaryContainer to Hero/Card Contours Only

**Files to modify:**
- `lib/features/home/presentation/widgets/hero_countdown_card.dart`
- Scan for any other PrimaryContainer usage outside hero/card

**Context:**
- Reduce PrimaryContainer usage to hero/card contours only as per DESIGN.md
- Replace excessive PrimaryContainer usage (e.g., in buttons, chips) with secondaryContainer/onSecondaryContainer

**Global Constraints:**
- PrimaryContainer used only for:
  - Hero countdown card background outer appearance
  - Avatar border
- Replace other PrimaryContainer usages with:
  - secondaryContainer/onSecondaryContainer for card canvas
  - secondaryContainer/onSecondaryContainer for chips/accent items

**Implementation Steps:**
1. Audit PrimaryContainer usage:
   - Command: `grep -rn "primaryContainer" lib/features/home/presentation/widgets/`
   - List all usages outside hero_countdown_card
   - Flag any unexpected usages (e.g., buttons, chips)
2. Fix Hero Countdown Card:
   - Open `lib/features/home/presentation/widgets/hero_countdown_card.dart`
   - Confirm primaryContainer/onPrimaryContainer used only for:
     - Hero countdown card background outer appearance
     - Avatar border
   - Verify no other components use primaryContainer unrelated to hero/card
3. Replace Excessive PrimaryContainer (if any):
   - If avatar border uses other container, fine
   - If avatar border uses primaryContainer, keep as accent (intentional)
   - If primaryContainer appears in unexpected locations (e.g., buttons, chips):
     - Card canvas background → secondaryContainer/onSecondaryContainer
     - Chips/Accents → secondaryContainer/onSecondaryContainer
4. Run Analysis:
   - Command: `flutter analyze lib/features/home/presentation/widgets/hero_countdown_card.dart`
   - Expected: 0 mismatches, verify colors used only as per DESIGN.md
5. Commit: `refactor(theme): limit primaryContainer to hero/card contours per DESIGN.md`

**Deliverables:**
- Modified hero_countdown_card.dart (conservative PrimaryContainer usage)
- Analysis clean
- Commit in history

**Report-file path:** `docs/superpowers/plans/task-4-report.md`

**Self-review checklist:**
- [ ] PrimaryContainer used only in hero/card contours
- [ ] No unexpected PrimaryContainer usage in buttons/chips
- [ ] Colors match DESIGN.md spec for hero cards
- [ ] `flutter analyze` clean
- [ ] Commit message matches pattern

**Testing:**
- `flutter analyze lib/features/home/presentation/widgets/hero_countdown_card.dart` → expected 0 errors
- No color mismatches detected

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED