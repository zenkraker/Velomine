# Sidebar

The navigation from 1200 dp: the wordmark, the main destinations (four, or five with auto training), and the privacy note, Profile and the foot's controls.

**Recorded choice (design first):** there is **no Settings entry**. No route answers `/settings`, and every setting already has a page of its own — language, units and time zone in [ProfilePage](../profile/ProfilePage.html), then privacy, devices and sessions, two-factor and supporter — so a Settings entry would be a destination with nowhere to go. The foot ends on the privacy note, Profile, and one row of controls: the **theme choice**, the **notifications bell** with its unread count, and the **account menu**. The theme is a button, not a destination: it changes the theme in place. (Today's code has the same three, so this page and the code agree; the story's S13 is about the old page.)

**The consumer provides** the destinations and the current route: Rides ▾ (All rides, Routes, Bikes), Training (one page, only with auto training on), Progress ▾ (Overview, Fitness, Power, Totals, Wellbeing), Goals (one page, no sub-pages), and the member's club ▾ (Members, Club rides, Sharing). A section holding the current page opens by itself.

**Do**
- The current page sits on `accent-soft` in `on-accent-soft`, semibold. Hover is `card-raised`.
- Sections with pages open and close with a chevron; their pages are indented under the section's icon. A destination with one page (Training, Goals) is a plain link.
- The club section is named after the member's club; without a club it reads "Club" and opens the join page.
- The foot's row holds `ThemeChoiceButton`, the notifications bell (the same button the phone header shows, with the unread count) and the account menu, in that order, after Profile.
- The account menu holds the member's name, Profile, Admin for a server admin, Send feedback and Sign out — Sign out is the last entry, and the only destructive one.
- The same destinations, in the same order, are the phone's nav pill.

**Don't**
- Add a destination beyond these, or put a destructive action here: Sign out lives in the account menu at the foot of the sidebar.
- Add a Settings entry until there is a page it opens.
- Show counts or badges except unread notifications.

**Open question for the owner:** the story asks whether the foot gains a Settings entry or the theme control moves into the account menu; this page decides neither — the theme stays a button in the foot row, and no Settings page exists to link to.

**Flutter:** one widget for the expanded rail in `home_shell.dart` (`NavSidebar`, `_PrivacyNote`, `_AccountMenu`); from 600 to 1199 dp the destinations show as a collapsed rail of icons with labels, and on a phone as the nav pill.
