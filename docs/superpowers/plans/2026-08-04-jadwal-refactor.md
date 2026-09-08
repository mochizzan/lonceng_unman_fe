# Jadwal Page Refactor Plan

## Goal
Refactor the Jadwal (schedule) page to match the HTML template design:
- Clean header without app bar - only day selector
- Vertical timeline connecting all cards
- Refined card design with accent bars, time badges, and proper shadows
- Fix state management anti-patterns

## Source of Truth
HTML template provided by user (see attachment in conversation)

## Design Mapping (HTML → Flutter)

### 1. Page Structure
| HTML | Flutter | Notes |
|------|---------|-------|
| `<header>` (empty) | Remove SliverAppBar | No title/calendar icon |
| Day selector section | `JadwalDaySelector` | Already exists, minor style updates |
| Timeline section | New `_TimelineSection` widget | Vertical line + cards |

### 2. Color Mapping
| HTML Class | Flutter Theme | Value |
|------------|---------------|-------|
| `bg-primary` | `cs.primary` | `#785900` |
| `text-on-primary` | `cs.onPrimary` | `#FFFFFF` |
| `bg-primary-container` | `cs.primaryContainer` | `#FFC107` |
| `text-on-primary-container` | `cs.onPrimaryContainer` | `#6D5100` |
| `bg-surface` | `cs.surface` | `#FFFFFF` |
| `bg-surface-variant` | `cs.surfaceVariant` | `#F5F0E6` |
| `text-on-surface` | `cs.onSurface` | `#201B11` |
| `text-on-surface-variant` | `cs.onSurfaceVariant` | `#4F4632` |
| `bg-outline-variant` | `cs.outlineVariant` | `#D4C5AB` |
| `border-surface-container-highest` | `cs.surfaceContainerHighest` | `#ECE1D0` |
| `bg-tertiary` | `cs.tertiary` | `#006877` |
| `bg-secondary` | `cs.secondary` | `#6E5C3D` |
| `shadow-[0px_4px_12px_rgba(0,0,0,0.06)]` | BoxShadow | `blur: 12, spread: 0, offset: (0,4), color: black@6%` |

### 3. Typography
| Element | HTML | Flutter |
|---------|------|---------|
| Course name | `font-title-md` (18px/600) | `TextStyle(fontSize: 18, fontWeight: FontWeight.w600)` |
| Lecturer | `font-body-md` (14px/400) | `TextStyle(fontSize: 14, fontWeight: FontWeight.normal)` |
| Time badge | `font-label-md` (12px/500) | `TextStyle(fontSize: 12, fontWeight: FontWeight.w500)` |
| Location/SKS | `font-label-md` (12px/500) | `TextStyle(fontSize: 12, fontWeight: FontWeight.w500)` |
| "Sedang Berlangsung" | `font-label-md` uppercase | `TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)` |

### 4. Shape
| Element | HTML | Flutter |
|---------|------|---------|
| Day pills | `rounded-full` | `BorderRadius.circular(999)` |
| Cards | `rounded-[20px]` | `BorderRadius.circular(20)` |
| Time badge | `rounded-full` | `BorderRadius.circular(999)` |
| Timeline dot | `rounded-full` | `BoxShape.circle` |

## Implementation Tasks

### Task 1: Remove SliverAppBar, Clean Page Structure
**File:** `lib/features/jadwal/presentation/pages/jadwal_page.dart`

**Changes:**
- Remove `SliverAppBar` widget entirely
- Change from `CustomScrollView` to `Column` with:
  - `JadwalDaySelector` at top (with horizontal padding)
  - Expanded `_TimelineSection` widget
- Fix state mutation anti-pattern (lines 73-74)
- Add `const` where possible

**Before:**
```dart
CustomScrollView(
  slivers: [
    SliverAppBar(...),
    SliverToBoxAdapter(child: JadwalDaySelector(...)),
    SliverPadding(sliver: SliverList(...)),
  ],
)
```

**After:**
```dart
Column(
  children: [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: JadwalDaySelector(...),
    ),
    SizedBox(height: 24),
    Expanded(
      child: _TimelineSection(items: items),
    ),
  ],
)
```

---

### Task 2: Create Timeline Section Widget
**File:** `lib/features/jadwal/presentation/widgets/jadwal_timeline.dart` (NEW)

**Purpose:** Container for vertical timeline with connecting line

**Implementation:**
```dart
class JadwalTimeline extends StatelessWidget {
  const JadwalTimeline({super.key, required this.items});

  final List<JadwalScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(items.length, (index) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot column
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _buildDot(cs, items[index], index),
                      if (index < items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: JadwalCard(item: items[index], index: index),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDot(ColorScheme cs, JadwalScheduleItem item, int index) {
    final isOngoing = item.status == JadwalScheduleStatus.ongoing;

    if (isOngoing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: _PulsingDot(color: cs.primary),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant, width: 4),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
```

---

### Task 3: Redesign JadwalCard
**File:** `lib/features/jadwal/presentation/widgets/jadwal_card.dart`

**Changes:**
1. **Ongoing card (index 0):**
   - Background: `cs.primaryContainer`
   - No accent bar
   - "Sedang Berlangsung" label
   - Time badge: `onPrimaryContainer.withValues(alpha: 0.15)` bg

2. **Upcoming cards (index 1+):**
   - Background: `cs.surface`
   - Border: `cs.surfaceContainerHighest`
   - Accent bar on left (tertiary for index 1, secondary for index 2+)
   - No status label
   - Time badge: `cs.surfaceVariant` bg

3. **Card structure:**
```
┌─────────────────────────────────────────┐
│ [Accent Bar] Course Name    [Time Badge]│
│              Lecturer Name              │
├─────────────────────────────────────────┤
│ 📍 Room              🎫 SKS            │
└─────────────────────────────────────────┘
```

**Implementation:**
```dart
class JadwalCard extends StatelessWidget {
  const JadwalCard({super.key, required this.item, required this.index});

  final JadwalScheduleItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOngoing = item.status == JadwalScheduleStatus.ongoing;
    final isSoon = index == 1;

    // Background and border
    final bgColor = isOngoing ? cs.primaryContainer : cs.surface;
    final borderColor = isOngoing ? null : cs.surfaceContainerHighest;

    // Accent bar color
    Color? accentColor;
    if (!isOngoing) {
      accentColor = isSoon ? cs.tertiary : cs.secondary;
    }

    // Time badge colors
    final timeBadgeBg = isOngoing
        ? cs.onPrimaryContainer.withValues(alpha: 0.15)
        : cs.surfaceVariant;
    final timeBadgeText = isOngoing
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status label (ongoing only)
            if (isOngoing) ...[
              Text(
                'SEDANG BERLANGSUNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Course name + time badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent bar (upcoming only)
                if (accentColor != null) ...[
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isOngoing
                              ? cs.onPrimaryContainer
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.lecturer ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: isOngoing
                              ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: timeBadgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: timeBadgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: isOngoing
                  ? cs.onPrimaryContainer.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            // Location + SKS row
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: isOngoing
                      ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  item.room,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.confirmation_number,
                  size: 18,
                  color: isOngoing
                      ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  item.sks,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOngoing
                        ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

---

### Task 4: Add PulsingDot Widget
**File:** `lib/features/jadwal/presentation/widgets/jadwal_timeline.dart`

**Implementation:**
```dart
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

### Task 5: Update Day Selector Styles
**File:** `lib/features/jadwal/presentation/widgets/jadwal_day_selector.dart`

**Changes:**
- Active pill: `cs.primary` bg + `cs.onPrimary` text (not primaryContainer)
- Inactive pill: `cs.surfaceContainerHighest` bg + `cs.onSurfaceVariant` text
- Add shadow for active pill: `BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 8)`

---

### Task 6: Fix State Management
**File:** `lib/features/jadwal/presentation/pages/jadwal_page.dart`

**Changes:**
- Move `_selectedDay` and `_days` initialization outside of `BlocBuilder.builder`
- Use `BlocListener` for side effects instead of mutating state in builder
- Consider dispatching `JadwalDayChanged` event when day changes (optional enhancement)

---

## Task Dependencies

```
Task 1 (Page Structure) ──┐
                          ├──→ Task 3 (Card Redesign) ──→ Final Integration
Task 2 (Timeline Widget) ─┘
Task 4 (PulsingDot) ────────┘
Task 5 (Day Selector) ──────→ Final Integration
Task 6 (State Fix) ─────────→ Final Integration
```

## Parallel Execution Plan

**Wave 1 (Independent):**
- Task 1: Page structure refactor
- Task 2: Timeline widget creation
- Task 5: Day selector style update
- Task 6: State management fix

**Wave 2 (Depends on Wave 1):**
- Task 3: Card redesign (needs timeline structure)
- Task 4: PulsingDot (part of timeline)

**Wave 3:**
- Final integration testing
- Flutter analyze
- Visual verification

## Verification

1. `flutter analyze` - zero issues
2. Visual comparison with HTML template
3. Day selector interaction works
4. Timeline line connects all dots
5. Ongoing card has pulse animation
6. Upcoming cards have accent bars
7. All colors from theme (no hardcoded values)
