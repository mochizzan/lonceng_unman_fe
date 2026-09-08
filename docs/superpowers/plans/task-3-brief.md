# Task 3: Fix Inconsistent UI String Casing & Typos

**Files to modify:**
- `lib/features/home/presentation/bloc/home_bloc.dart`
- `lib/features/home/presentation/bloc/home_state.dart`
- Any other feature file using inconsistent casing (scan first)

**Context:**
- Audit found inconsistent string casing: "Ter hadir" → should be "Terhadap"
- Need to fix case inconsistencies and typos in UI labels
- Also apply Title Case to UI labels throughout the codebase

**Global Constraints:**
- UI labels: Title Case (e.g., "NPM", "Prodi", "Semester")
- Internal/Blo c identifiers: camelCase (e.g., `AuthSubmitted`, `GetJadwal`)
- Fix typo: "Ter hadir" → "Terhadap"
- Keep internal identifiers in camelCase unchanged

**Implementation Steps:**
1. Scan for typos and inconsistencies:
   - Run: `grep -r "Ter [ai]" lib/features/`
   - Run: `grep -r "sedang_[colon]berlangsung" lib/features/`
   - Run: `grep -iE "(masuk|login|npm|prodi|sem)" lib/features/—` lib/features/*/presentation/bloc/*.dart lib/features/*/presentation/pages/*.dart | grep -v "camelCase"`
2. Fix home_bloc error messages:
   - Open `lib/features/home/presentation/bloc/home_bloc.dart`
   - Replace any instance of `"Ter hadir"` → `"Terhadap"` (if error message)
   - Keep `"sedang_berlangsung"` as-is if used as state enum (ensure UI uses same)
3. Fix home_state labels:
   - Open `lib/features/home/presentation/bloc/home_state.dart`
   - Replace `"Ter hadir"` → `"Terhadap"` in display text
   - Ensure any label strings use Title Case
4. Enforce Title Case for UI labels in:
   - `login_page.dart`: Replace `"npm"` → `"NPM"`, `"prodi"` → `"Prodi"`, `"sem"` → `"Semester"`
   - `jadwal_page.dart`: Same casing replacements
   - `profile_page.dart`: Same casing replacements
   - Keep internal identifiers in camelCase unchanged
5. Verify with grep:
   - Command: `flutter analyze lib/features/home/`
   - Scan for `deprecated_member_use` manually
6. Commit message: `fix: standardize UI string casing and fix typo 'Ter hadir' → 'Terhadap'`

**Deliverables:**
- Modified home_bloc.dart home_state.dart
- Uppercase/lowercase normalized for UI labels
- Analysis clean
- Commit in history

**Report-file path:** `docs/superpowers/plans/task-3-report.md`

**Self-review checklist:**
- [ ] "Ter hadir" → "Terhadap" fixed (in both bloc and state)
- [ ] UI labels use Title Case (NPM, Prodi, Semester)
- [ ] Internal identifiers remain camelCase
- [ ] No unintended changes to code logic
- [ ] `flutter analyze` clean
- [ ] Commit message matches pattern

**Testing:**
- `flutter analyze lib/features/home/` → expected 0 errors
- No resulting logic changes (law r-label casing)

**Implementer Status Required:** DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED