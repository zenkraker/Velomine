# WellbeingPage

Progress → Wellbeing answers "How do I feel, and why is my readiness what it is?". Wellbeing is health data: only the owner sees this page.

**The consumer provides** the readiness score with its factors and their effects, today's check-in, and how the rider felt over the last 14 days. Before the first check-in, the consent card replaces the page.

**Layout**
- Title row: "Progress" caption, `page-title`, the filled **Check in** button (opens a form sheet) and the `⋯` menu, where Withdraw consent sits last, in `danger`.
- Halves: **Readiness** (score, state chip, advice, and the note that it is a guide, not a medical measure) and **Why 50**: one row per factor with its value and its effect drawn from a centre line, `accent-strong` when it raises the score, `signal` when it lowers it, with the signed number.
- Full width: **How you feel** over 14 days, and the note on who can see what.

**Don't** show notes to anyone but the owner, or put readiness on a coach's view.
