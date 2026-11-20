# StatCard

One fact on a card: a title, one big number, one sentence that explains it, and one link to its details.

**The consumer provides** the title, the value and its unit (already formatted for the language), one sentence, and the route the link opens. An optional state (a word such as "Go easy") shows as a chip after the number.

**Use it** for the summary row of an overview page, up to four in a row from 1200 dp, two per row on a phone.

**Do**
- Number in `kpi`, unit in `ink-muted` at caption size.
- The sentence says what the number means for the rider.
- The link names the detail page: "Power →", "All weeks →".

**Don't**
- Put two numbers on one card, or a number another card on the same page already shows.
- Add an icon tile, an uppercase eyebrow, a border or a shadow.
- Clip the sentence: it wraps.

**Flutter:** a `StatCard` in `lib/core/widgets/` replaces today's `StatTile` and the hand-made tiles in `progress_screen.dart`.
