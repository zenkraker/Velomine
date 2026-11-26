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
- The page's one main action and its `⋯` menu sit at the **end of the title row, level with the title** — the top-right corner of the page. Never centred over the content, never on a row of their own. `PageScaffold` owns this: do not place a page action anywhere else.
- No empty columns or dead space.
- Columns: compact 1, medium 2, expanded as the Plan's wireframe says. Build splits with `Row` + `Expanded(flex:)`; cards in one row have equal height.
- Spacing from the spacing constants (4, 8, 12, 16, 24, 32, 48). No literal `EdgeInsets` values.
- Colors, text styles and radii from `Theme.of(context)`. No `Color(0x…)` or `TextStyle(fontSize: …)` in widgets.
- `SafeArea` on mobile; touch targets ≥ 48×48 dp.

## Controls

- Period selectors are `SegmentedButton`s; sport filters are `FilterChip`s.

## Text

- One body size: 15. Body copy is `bodyLarge` or `bodyMedium` (both 15, per `docs/design/pages/README.md`); a number or detail smaller than that is `caption` 13, never a hand-picked 14.
- Never clip explanatory text: no fixed heights around wrapping text. `maxLines` + ellipsis only on single-line labels.
- All copy from `.arb` files (both languages, per AGENTS.md). Dates via `intl` `DateFormat`, one format per page.

## Charts

- Every chart is drawn by `fl_chart` through `core/widgets/` (`AreaChart`, `BarChart`, `GoalGauge`); never write a chart painter, and never import `fl_chart` from a feature. A chart the library cannot express is a special case for the owner (`AGENTS.md`, *App*).
- Axis labels never overlap: compute the label interval from available width; fewer labels on compact.
- Title, units, legend or direct labels on every chart.
- Round Y-axis ticks (0, 10, 20…), not data extremes.
- Empty data → the empty state from the Plan, not empty bars or a flat line.
- Current period highlighted with `colorScheme.primary`, others muted.

## States

Build loading, empty, error and populated for every data widget the Plan lists.

## Screenshot check (before `just check`)

1. Give each changed page a widget test per width, like the existing `<Screen>_ShouldNotOverflow_WhenWidthIs<N>` tests (390, 600, 820 and 1300 dp), with fake data. A "RenderFlex overflowed" error fails it: fix the layout. Don't hide it with `ClipRect` or a scroll view the Plan didn't ask for.
2. Look at the page, from a Chrome session on the web UI at every width the Plan covers. `just up` puts the app on http://localhost:8080, and only there does the session cookie work, so do not use `flutter run -d chrome` for this:

   ```
   dart run tools/screenshots.dart --routes /rides,/progress/fitness --widths 390,600,820,1300
   ```

   It drives one headless Chrome over the DevTools protocol: signs in as the dev account (`admin@velomine.local` / `Velomine-dev-1`, `docs/development.md`), sets the viewport with `Emulation.setDeviceMetricsOverride` per width, waits for the frame to settle, and writes `.dev/screens/<screen>-<width>.png`. Add `--theme day` for the Day theme; Night is the default. Compare each shot with the page's mock-up (`docs/design/pages/<area>/<Page>.html`) at 390 and 1300 at least, and at 600 and 820 when the page draws a different structure there (columns, drop area, rail).
   - If `tools/screenshots.dart` or a Chrome binary is missing, the check cannot pass: say that in **Checks**, never report it as passed from reading code. Never trust a screenshot you did not take in this run.
   - A blank, unstyled or sign-in screenshot is a harness failure, not a pass: fix the harness (port, session, wait) and take it again.
3. Pass/fail each item, and put the list in your report under **Checks**:
   - [ ] Matches the Plan's wireframes at phone and desktop width
   - [ ] Navigation matches the size class
   - [ ] No empty columns or dead space
   - [ ] No clipped or overlapping text, including axis labels
   - [ ] No number repeated on one screen
   - [ ] Spacing, colors, text styles from theme/constants
   - [ ] Loading, empty, error states exist
4. Fix failures in your code and re-run. A failure caused by the Plan → NEEDS_CONTEXT.
