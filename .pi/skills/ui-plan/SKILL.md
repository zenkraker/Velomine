---
name: ui-plan
description: How to structure Velomine screens (pages, tabs, routes, navigation, what goes on each page). Use when writing a Plan for any story that adds or changes a screen in app/.
---

# Planning Velomine screens

The Developer builds exactly what the Plan says and does not redesign. Every structural UI decision must therefore be in the Plan. If it isn't, the Developer stops with NEEDS_CONTEXT.

The app is Flutter, shipped to web and iOS/Android from the same widgets. Plan every screen for three Material 3 window size classes:

| Class | Width (dp) | Typical device | Navigation |
|---|---|---|---|
| compact | < 600 | phone | `NavigationBar` (bottom) |
| medium | 600–839 | tablet portrait, small browser | `NavigationRail` |
| expanded | ≥ 840 | tablet landscape, desktop web | sidebar |

## Rules

- Every page answers ONE main question.
- At most 5 cards per page or tab. More than that → split into tabs or routes.
- Max 3 levels per page: headline numbers, one primary chart, details.
- Each number appears once per screen. Elsewhere, link to it.
- KPI rows: max 4 tiles.
- A control sits next to what it changes. Period selectors and sport filters are different controls and never share a row.
- Long explanations go behind an info icon (tooltip / bottom sheet), not in cards.

## What the Plan's *Screens* section must contain

1. **The question** each changed page answers.
2. **Route/tab map**: which route or tab holds which widgets (only the part that changes).
3. **ASCII wireframes** of each changed page at compact AND expanded width, with each card named and its column span at expanded width (full, 2/3+1/3, 1/2+1/2, 1/3×3).
4. **Data states** to build per widget: loading, empty (with its Italian copy), error.
5. **New `.arb` strings** with Italian text (and the other language, per AGENTS.md).
6. **Shared pieces**: whether `PageScaffold` already handles max width, padding and navigation per size class. If it doesn't and the story needs it, plan that change in *Files to change*.
7. **Which widths each page is tested at** (the `_ShouldNotOverflow_WhenWidthIs<N>` tests), and the fake data they need.

## Velomine page map (target structure)

| Route | Question it answers | Contents |
|---|---|---|
| `/progress` (Overview) | "How am I today and this week?" | Readiness card, this-week KPIs, weekly distance chart, link to goals |
| `/progress/fitness` | "Is my fitness going up?" | Fitness/fatigue/form chart, daily load, easy/moderate/hard distribution, range selector |
| `/progress/power` | "What is my power profile?" | Power curve, best efforts, FTP, critical power, VO2max, aerobic efficiency |
| `/progress/totals` | "What did I do in each week/month/year?" | Period list (weeks/months/years) |
| `/progress/wellbeing` | "How do I feel?" | Check-ins and ride RPE |
| `/goals` | "Am I hitting my goals?" | Goals list, add goal |

`docs/design/pages/README.md` owns the full route list. Tabs inside Progress (`ProgressTabs`): Overview · Fitness · Power · Totals · Wellbeing. The sport filter sits in the page header and applies to all tabs; on compact width it becomes a dropdown or a horizontally scrolling chip row.

When a story conflicts with this map, raise it with the PO instead of silently deviating. Update this table when the owner approves a change.

## References

If `design/references/` exists, look at the screenshots there before wireframing and match their structure and density.
