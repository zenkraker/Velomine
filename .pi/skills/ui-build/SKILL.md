---
name: ui-build
description: Rules for building Flutter widgets in app/ (layout, theme, text, charts, states) and the screenshot check that proves the result. Use whenever a story changes anything visible in app/.
---

# Building Velomine screens

The Plan's *Screens* section decides structure (pages, tabs, cards, wireframes). This skill decides how you build it. If the Plan has no wireframe for a screen you must change, or the screenshots show the Plan's layout cannot work (e.g. more than 5 cards on a tab, a number shown twice), stop with NEEDS_CONTEXT. Do not redesign.

These rules apply to widgets you create or change. Existing code outside the Plan that breaks them: leave it, and list it in **Concerns**.

## Layout

- Every screen uses `PageScaffold`. Content width (1160), padding (16 / 24 / 32 by size class) and navigation (`FloatingNavPill` under 600 dp, collapsed rail from 600 dp, `NavSidebar` from 1200 dp) belong there, not in pages. If `PageScaffold` lacks one of these and the Plan doesn't change it, NEEDS_CONTEXT.
- Size classes (compact < 600, medium 600–1199, expanded ≥ 1200) come from `AppBreakpoint` in `lib/core/tokens.dart`. Never compare raw widths inside a widget.
- No empty columns or dead space.
- Columns: compact 1, medium 2, expanded as the Plan's wireframe says. Build splits with `Row` + `Expanded(flex:)`; cards in one row have equal height.
- Spacing from the spacing constants (4, 8, 12, 16, 24, 32, 48). No literal `EdgeInsets` values.
- Colors, text styles and radii from `Theme.of(context)`. No `Color(0x…)` or `TextStyle(fontSize: …)` in widgets.
- `SafeArea` on mobile; touch targets ≥ 48×48 dp.

## Controls

- Period selectors are `SegmentedButton`s; sport filters are `FilterChip`s.

## Text

- Never clip explanatory text: no fixed heights around wrapping text. `maxLines` + ellipsis only on single-line labels.
- All copy from `.arb` files (both languages, per AGENTS.md). Dates via `intl` `DateFormat`, one format per page.

## Charts

- Axis labels never overlap: compute the label interval from available width; fewer labels on compact.
- Title, units, legend or direct labels on every chart.
- Round Y-axis ticks (0, 10, 20…), not data extremes.
- Empty data → the empty state from the Plan, not empty bars or a flat line.
- Current period highlighted with `colorScheme.primary`, others muted.

## States

Build loading, empty, error and populated for every data widget the Plan lists.

## Screenshot check (before `just check`)

1. Give each changed page a widget test per width, like the existing `<Screen>_ShouldNotOverflow_WhenWidthIs<N>` tests (390, 600, 820 and 1300 dp), with fake data. A "RenderFlex overflowed" error fails it: fix the layout. Don't hide it with `ClipRect` or a scroll view the Plan didn't ask for.
2. With a running app (`just phone` or the web build), look at the page at phone and desktop width and compare it with the Plan's wireframes.
3. Pass/fail each item, and put the list in your report under **Checks**:
   - [ ] Matches the Plan's wireframes at phone and desktop width
   - [ ] Navigation matches the size class
   - [ ] No empty columns or dead space
   - [ ] No clipped or overlapping text, including axis labels
   - [ ] No number repeated on one screen
   - [ ] Spacing, colors, text styles from theme/constants
   - [ ] Loading, empty, error states exist
4. Fix failures in your code and re-run. A failure caused by the Plan → NEEDS_CONTEXT.
