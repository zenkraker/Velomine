# ProgressPhone

The Progress overview on a phone (under 600 dp): the same cards as on the desktop in one column, the sub-pages as tabs at the top, and the glass nav pill floating over the bottom.

**The consumer provides** the rider's numbers for the chosen sport.

**Layout**
- Title row: `page-title`, the sport as one chip that opens a sheet ("Road ▾"), and the `⋯` menu.
- Tabs as chips that scroll sideways: Overview, Fitness, Power, Totals, Wellbeing.
- Readiness full width; Form and This week side by side (smaller `kpi`, no link: the whole card opens its page); Next event; Distance per week with its period control.
- Bar labels every third week. Page padding `space-lg`; room under the last card for the pill.
