# ProgressDesktop

The Progress overview from 1200 dp: it answers only "How am I today and this week?", and every card opens the sub-page that answers the next question.

**The consumer provides** the rider's numbers for the chosen sport.

**Layout**
- Sidebar (240 px) with Progress open and Overview current; content at most 1160 px wide.
- Title row: `page-title` and the `⋯` menu. Under it, the sport filter chips, for the whole page.
- With auto training on, a slim **Today** strip under the chips: "Today · Sweet spot 3×10 · 1 h 15", linking to Training ("Training →"). On a rest day it reads "Today · Rest day"; with auto training off it is not there. It is a link, not a fact card: it adds no number to the page.
- Row 1, four stat cards, each linking to its sub-page:
  - **Readiness** (score and state) → Wellbeing
  - **Form** (today's form, "Building", fitness and fatigue in the sentence) → Fitness
  - **This week** (distance, against the 12-week average) → Totals
  - **Next event** (days to go); with no event planned, the latest record instead → Goals
- Row 2, full width: Distance per week with its period control → Totals. It grows to the bottom of the window, so the content ends level with the sidebar.

**The Progress sub-pages**, one question and one main chart each:

| Page | Question | Main chart |
|---|---|---|
| Fitness | Is my fitness going up? | Fitness, fatigue and form |
| Power | What is my power profile? | Power curve |
| Totals | What did I do each week, month, year? | Totals chart and table |
| Wellbeing | How do I feel, and why that readiness? | Readiness factors and how you feel |

FTP is the headline of Power, not of the overview: it changes every few weeks, not every day.
