# Task 6: Final Verification & Stabilization

**Files to verify:**
- All presentation files for final consistency check
- Link plan's Audit Report section at docs/superpowers/plans/2026-08-04-theme-consistency.md#audit-report

**Context:**
- Tasks 1-5 completed; verify all critical fixes applied
- Run full test suite
- Generate audit report documenting compliance
- Commit final cleanup

**Global Constraints:**
- Verify `flutter analyze` returns 0 errors
- Verify no hardcoded hex literals in runtime code
- Verify navbar uses AppColors
- Verify color scheme values (primaryContainer, secondaryContainer)
- All 66 tests must pass
- Commit message: `chore(theme): complete consistency refactor — navbar, colors, casing, shadows verified`

**Implementation Steps:**
1. Verify All Critical Fixes Applied:
   - Run: `flutter analyze` → Expected: 0 errors
   - Run: `grep -rn "0x[0-9A-F]{8}" lib/features/presentation/ lib/core/routes/ --include="*.dart" | grep -v "comment\|const Color " | grep -v "0xFF" | head -20`
   - Verify zero live hex literals in presentation/runtime code

2. Verify Navbar Uses AppColors:
   - Run: `grep -rn "navbar.*Color\|Color.*navbar" lib/core/routes/ --include="*.dart"`
   - Verify no hidden const navbar colors remain

3. Verify Color Scheme Deployed:
   - Scan `app_theme.dart`:
     - Light: `primaryContainer #FFC107` ✅
     - Light: `secondaryContainer #FFDB92` ✅
     - Dark: `primaryContainer #FFC107` ✅
     - Dark: `secondaryContainer #FFC340` ✅
   - Confirm no duplicate `secondaryContainer` negative mismatch

4. Run Final Full Test Suite:
   - Command: `flutter test`
   - Expected: All existing tests pass (66 tests)
   - No regressions introduced by theme changes

5. Generate Audit Summary Report:
   - Command:
     ```bash
     flutter analyze 2>&1 > /dev/null && echo "ANALYZER CLEAN" || echo "ANALYZER FAILED"
     flutter test 2>&1 | tail -3
     git diff --stat
     ```
   - Append results into `docs/superpowers/plans/2026-08-04-theme-consistency.md#audit-report` if needed

6. Final Commit:
   - Bash:
     ```bash
     git add -A
     git commit -m "chore(theme): complete consistency refactor — navbar, colors, casing, shadows verified"
     ```

**Deliverables:**
- Audit report documenting all verifications
- All 66 tests passing
- Final commit in history
- Updated plan with audit results

**Report-file path:** `docs/superpowers/plans/task-6-report.md`

**Self-review checklist:**
- [ ] All critical fixes validated (navbar, colors, shadows)
- [ ] flutter analyze returns 0 errors
- [ ] 66 tests pass
- [ ] No hardcoded hex literals remaining
- [ ] Color scheme values match DESIGN.md
- [ ] Commit message matches pattern

**Testing:**
- `flutter analyze` → expected 0 errors
- `flutter test` → expected all 66 tests pass
- Verification via grep confirmed zero live hex literals

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED