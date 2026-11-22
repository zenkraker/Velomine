# Sidebar

The navigation from 1200 dp: the wordmark, the main destinations (four, or five with auto training), and the privacy note, profile and settings at the bottom.

**The consumer provides** the destinations and the current route: Rides ▾ (All rides, Routes, Bikes), Training (one page, only with auto training on), Progress ▾ (Overview, Fitness, Power, Totals, Wellbeing), Goals (one page, no sub-pages), and the member's club ▾ (Members, Club rides, Sharing). A section holding the current page opens by itself.

**Do**
- The current page sits on `accent-soft` in `on-accent-soft`, semibold. Hover is `card-raised`.
- Sections with pages open and close with a chevron; their pages are indented under the section's icon. A destination with one page (Training, Goals) is a plain link.
- The club section is named after the member's club; without a club it reads "Club" and opens the join page.
- The same destinations, in the same order, are the phone's nav pill.

**Don't**
- Add a destination beyond these, or put a destructive action here (Sign out lives in the account menu at the foot of the sidebar).
- Show counts or badges except unread notifications.

**Flutter:** one widget for the expanded rail in `home_shell.dart`; from 600 to 1199 dp the destinations show as a collapsed rail of icons with labels, and on a phone as the nav pill.
