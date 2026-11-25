import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/back_guard.dart';
import 'core/hooks.dart';
import 'core/l10n.dart';
import 'core/motion.dart';
import 'core/providers.dart';
import 'core/rider_mode.dart';
import 'core/theme_choice.dart';
import 'core/tokens.dart';
import 'core/widgets/floating_nav_pill.dart';
import 'core/widgets/page_scaffold.dart';
import 'features/club/club_view_model.dart';
import 'features/notifications/notifications_view_model.dart';
import 'features/profile/rider_mode_sheet.dart';
import 'features/profile/rider_mode_view_model.dart';
import 'features/recording/live_ride_banner.dart';
import 'features/training/training_view_model.dart';
import 'features/recording/recording_providers.dart';

/// One tab of the shell: where it goes, its outlined and filled icons and its label.
typedef _Tab = ({String path, Widget icon, Widget selectedIcon, String label});

/// The frame around the signed-in screens: the same four destinations — Rides, Progress, Goals, Club — at
/// every width. On a phone they are a floating pill over the page; from 600 dp a rail; from 1200 dp the
/// sidebar with each destination's pages under it, the rider's club among them. Every page names itself with
/// its own header, and the shell hands that header the notifications, the account and the way back through a
/// [PageHeaderScope].
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  /// The destinations of the shell. Training is the fifth, after Rides, and only while auto training is on.
  List<_Tab> _tabs(BuildContext context, bool autoTraining) => [
    (
      path: '/rides',
      icon: const Icon(Icons.directions_bike_outlined),
      selectedIcon: const Icon(Icons.directions_bike),
      label: context.l10n.navRides,
    ),
    if (autoTraining)
      (
        path: '/training',
        icon: const Icon(Icons.event_available_outlined),
        selectedIcon: const Icon(Icons.event_available),
        label: context.l10n.navTraining,
      ),
    (
      path: '/progress',
      icon: const Icon(Icons.insights_outlined),
      selectedIcon: const Icon(Icons.insights),
      label: context.l10n.navProgress,
    ),
    (
      path: '/goals',
      icon: const Icon(Icons.flag_outlined),
      selectedIcon: const Icon(Icons.flag),
      label: context.l10n.navGoals,
    ),
    (
      path: '/club',
      icon: const Icon(Icons.groups_outlined),
      selectedIcon: const Icon(Icons.groups),
      label: context.l10n.navClub,
    ),
  ];

  /// A route that is not one of the tabs was pushed, so it offers the way back.
  bool _pushed(List<_Tab> tabs) => !tabs.any((tab) => tab.path == location);

  static void _back(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else {
      context.go('/rides');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionViewModelProvider);
    final unread = ref.watch(
      notificationsViewModelProvider.select((state) => state.unread),
    );
    // The operator's switch hides the destination too, whatever the member's own plan says.
    final autoTraining =
        ref.watch(trainingViewModelProvider).on &&
        (state.serverInfo?.autoTrainingEnabled ?? false);
    final tabs = _tabs(context, autoTraining);
    // The Progress sub-pages are destinations of Progress, not screens pushed over it: Progress stays lit
    // and their back arrow leads to the overview.
    final sectionRoot = _sectionRootOf(location);
    final pushed = sectionRoot == null && _pushed(tabs);
    // A pushed screen lights no destination, except the events page: it belongs to Goals, which is where
    // an event is added and read.
    final selected = sectionRoot != null
        ? tabs.indexWhere((tab) => tab.path == sectionRoot)
        : location == '/progress/events'
        ? tabs.indexWhere((tab) => tab.path == '/goals')
        : pushed
        ? -1
        : tabs.indexWhere((tab) => tab.path == location);
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= AppBreakpoint.expandedWidth;
    final wide = width >= AppBreakpoint.compactWidth;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    // A ride in progress is one tap away from every screen but its own. No recorder (the web) means none.
    final recorder = ref.watch(recorderProvider);
    final snapshot = ref.watch(recorderSnapshotViewModelProvider);
    final live =
        recorder != null &&
        (snapshot.isRecording || snapshot.isPaused) &&
        location != '/record';
    final banner = live ? LiveRideBanner(snapshot: snapshot) : null;

    final club = ref.watch(clubViewModelProvider).club;
    final signOut = ref.read(sessionProvider).signOut;
    // The rail carries the notifications and the account from 600 dp; below that the page header does.
    final page = PageHeaderScope(
      showOnPhone: true,
      onBack: sectionRoot != null
          ? () => context.go(sectionRoot)
          : pushed
          ? () => _back(context)
          : null,
      trailing: [
        if (!wide) ...[
          // A phone's header holds the notifications on the destinations themselves; a section's
          // sub-pages carry their own action there, and the account menu still reaches the inbox.
          if (!pushed && sectionRoot == null)
            NotificationsButton(
              unread: unread,
              selected: location == '/notifications',
            ),
          _AccountMenu(
            name: state.me?.displayName,
            isAdmin: state.isAdmin,
            signedOut: signOut,
            avatar: true,
          ),
        ],
      ],
      child: RiderModePrompt(child: child),
    );

    return BackGuard(
      location: location,
      child: Scaffold(
        body: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (expanded)
                    NavSidebar(
                      location: location,
                      autoTraining: autoTraining,
                      clubName: club?.name,
                      unread: unread,
                      name: state.me?.displayName,
                      isAdmin: state.isAdmin,
                      signedOut: signOut,
                    )
                  else
                    _CollapsedRail(
                      tabs: tabs,
                      selected: selected < 0 ? null : selected,
                      location: location,
                      hasClub: club != null,
                      unread: unread,
                      name: state.me?.displayName,
                      isAdmin: state.isAdmin,
                      signedOut: signOut,
                    ),
                  Expanded(
                    child: _WithBanner(banner: banner, child: page),
                  ),
                ],
              )
            : _PhoneFrame(
                location: location,
                keyboard: keyboard,
                tabs: tabs,
                selected: selected < 0 ? null : selected,
                banner: banner,
                child: page,
              ),
      ),
    );
  }
}

/// A phone's page with the floating pill over it. The page scrolls under the pill; the pill hides while
/// the page scrolls down and returns when it scrolls up, and never hides under reduced motion.
class _PhoneFrame extends StatefulWidget {
  const _PhoneFrame({
    required this.location,
    required this.keyboard,
    required this.tabs,
    required this.selected,
    required this.banner,
    required this.child,
  });

  final String location;
  final bool keyboard;
  final List<_Tab> tabs;
  final int? selected;

  /// The live-ride banner while a ride is in progress, else null.
  final Widget? banner;
  final Widget child;

  @override
  State<_PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<_PhoneFrame> {
  bool _hidden = false;

  @override
  void didUpdateWidget(_PhoneFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new screen starts with the pill in view.
    if (oldWidget.location != widget.location) _hidden = false;
  }

  bool _onScroll(ScrollNotification n) {
    // Only the page's own list: a carousel or a map inside it must not move the pill.
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      final delta = n.scrollDelta ?? 0;
      final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
      if (atTop || delta < -AppNav.scrollThreshold) {
        _set(false);
      } else if (delta > AppNav.scrollThreshold) {
        _set(true);
      }
    }
    return false;
  }

  void _set(bool hidden) {
    if (_hidden != hidden) setState(() => _hidden = hidden);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The keyboard replaces the pill; the page then resizes and needs no room for it.
    final showPill = !widget.keyboard;
    final hidden = _hidden && !reduceMotion(context);
    // The banner keeps its place when the pill hides on scroll (it drops to the pill's slot), and the
    // page always leaves room for both, so the list never jumps under a finger.
    final bannerRoom = widget.banner == null
        ? 0.0
        : AppNav.bannerHeight + AppNav.bannerGap;
    final room = (showPill ? AppNav.pillClearance : 0.0) + bannerRoom;
    final safeBottom = media.padding.bottom;
    final pillSlot = showPill && !hidden
        ? AppNav.pillHeight + AppNav.bannerGap
        : 0.0;
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery(
            // Pages read the bottom padding to clear what floats over them.
            data: media.copyWith(
              padding: media.padding.copyWith(
                bottom: media.padding.bottom + room,
              ),
              viewPadding: media.viewPadding.copyWith(
                bottom: media.viewPadding.bottom + room,
              ),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
          ),
        ),
        AnimatedPositioned(
          duration: motionDuration(context, AppMotion.standard),
          curve: motionCurve(context, AppMotion.emphasized),
          left: AppNav.pillMargin,
          right: AppNav.pillMargin,
          bottom: safeBottom + AppNav.pillMargin + pillSlot,
          child: _BannerSwitcher(
            maxWidth: AppNav.pillMaxWidth,
            child: widget.banner,
          ),
        ),
        if (showPill)
          FloatingNavPill(
            visible: !hidden,
            selected: widget.selected,
            onSelected: (i) => context.go(widget.tabs[i].path),
            items: [
              for (final tab in widget.tabs)
                (
                  key: Key('tab-${tab.path.substring(1)}'),
                  icon: tab.icon,
                  selectedIcon: tab.selectedIcon,
                  label: tab.label,
                ),
            ],
          ),
      ],
    );
  }
}

/// Fades and grows the live-ride banner in and out, and stops animating under reduced motion.
class _BannerSwitcher extends StatelessWidget {
  const _BannerSwitcher({required this.child, this.maxWidth});

  final Widget? child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: motionDuration(context, AppMotion.standard),
    switchInCurve: motionCurve(context, AppMotion.emphasized),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SizeTransition(sizeFactor: animation, child: child),
    ),
    child: child == null
        ? const SizedBox.shrink(key: ValueKey('no-banner'))
        : Center(
            key: const ValueKey('banner'),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: child,
            ),
          ),
  );
}

/// A wide window's content with the live-ride banner along its foot.
class _WithBanner extends StatelessWidget {
  const _WithBanner({required this.banner, required this.child});

  final Widget? banner;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: child),
      _BannerSwitcher(
        maxWidth: AppLayout.contentMax,
        child: banner == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(AppNav.pillMargin),
                child: banner,
              ),
      ),
    ],
  );
}

/// Asks "How do you ride?" once, for an account that has not chosen: on the first sign-in, and never again once
/// the account holds a mode. It draws nothing itself: the question is a sheet over the page.
class RiderModePrompt extends ConsumerStatefulWidget {
  const RiderModePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RiderModePrompt> createState() => _RiderModePromptState();
}

class _RiderModePromptState extends ConsumerState<RiderModePrompt> {
  bool _opening = false;

  Future<void> _ask() async {
    if (!mounted) return;
    // Handled as soon as it opens, so the question appears at most once in this session.
    ref.read(riderModeViewModelProvider.notifier).promptShown();
    await showRiderModeSheet(context, firstTime: true);
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final asking =
        ref.watch(riderModeSituationProvider).prompt &&
        !ref.watch(riderModeViewModelProvider).promptHandled;
    if (asking && !_opening) {
      _opening = true;
      // After this frame: a sheet cannot open while the shell is building.
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
    }
    return widget.child;
  }
}

/// The notifications button with its unread count, the same in the page header and the rail.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({
    super.key,
    required this.unread,
    this.selected = false,
  });

  final int unread;
  final bool selected;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('open-notifications'),
    tooltip: unread == 0
        ? context.l10n.notifications
        : context.l10n.notificationsUnread(unread),
    isSelected: selected,
    icon: Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: const Icon(Icons.notifications_none),
    ),
    onPressed: () => context.push('/notifications'),
  );
}

/// The rail from 600 to 1199 dp: the four destinations as icons with their labels under them, and the
/// notifications and the account at the foot. A rider without a club sees "Club", which is the page that
/// offers the start and join choices. It draws no line: a tonal surface sets it apart from the page.
class _CollapsedRail extends StatelessWidget {
  const _CollapsedRail({
    required this.tabs,
    required this.selected,
    required this.location,
    required this.hasClub,
    required this.unread,
    required this.name,
    required this.isAdmin,
    required this.signedOut,
  });

  final List<_Tab> tabs;
  final int? selected;
  final String location;
  final bool hasClub;
  final int unread;
  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('nav-rail'),
      width: AppNav.railWidth,
      color: scheme.surfaceContainer,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final (i, tab) in tabs.indexed)
                    _RailDestination(
                      key: Key('rail-${tab.path.substring(1)}'),
                      icon: i == selected ? tab.selectedIcon : tab.icon,
                      label: tab.path == '/club' && !hasClub
                          ? l10n.navGroupClub
                          : tab.label,
                      selected: i == selected,
                      onTap: () => context.go(tab.path),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                spacing: AppSpacing.xs,
                children: [
                  NotificationsButton(
                    unread: unread,
                    selected: location == '/notifications',
                  ),
                  _AccountMenu(
                    name: name,
                    isAdmin: isAdmin,
                    signedOut: signedOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One page of the sidebar: where it goes, what it says, and the key a test finds it by.
typedef _NavPage = ({String path, String label, Key key});

/// One destination of the sidebar and the pages under it.
class _NavSection {
  const _NavSection({
    required this.id,
    required this.label,
    required this.icon,
    required this.pages,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<_NavPage> pages;
}

/// Which section holds each page, so a section opens by itself when one of its pages opens.
/// The Progress pages that belong to the Progress destination rather than being pushed over it. Their
/// back leads to the overview and the destination stays lit.
const _sectionRoots = <String, String>{
  '/progress/fitness': '/progress',
  '/progress/power': '/progress',
  '/progress/totals': '/progress',
  '/progress/wellbeing': '/progress',
};

String? _sectionRootOf(String location) => _sectionRoots[location];

const _sectionPages = <String, List<String>>{
  'rides': ['/rides', '/club/routes', '/bikes'],
  'progress': [
    '/progress',
    '/progress/fitness',
    '/progress/power',
    '/progress/totals',
    '/progress/wellbeing',
  ],
  'club': ['/club', '/club/rides', '/privacy'],
};

/// The navigation from 1200 dp: the wordmark, the four destinations with their pages under the sections,
/// the rider's club among them, and the privacy note, profile and account at the foot. A section opens by
/// itself when a page inside it opens, and stays open once the member has opened it.
class NavSidebar extends StatefulWidget {
  const NavSidebar({
    super.key,
    required this.location,
    required this.autoTraining,
    required this.clubName,
    required this.unread,
    required this.name,
    required this.isAdmin,
    required this.signedOut,
  });

  /// The route on screen: the page it names sits on the soft accent ground.
  final String location;

  /// Whether the rider has auto training on: then Training is a destination of its own after Rides.
  final bool autoTraining;

  /// The rider's club, or null when they are in none: then the club entry is one plain link to the join page.
  final String? clubName;
  final int unread;
  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  @override
  State<NavSidebar> createState() => _NavSidebarState();
}

class _NavSidebarState extends State<NavSidebar> {
  /// The sections showing their pages; the rest are folded away.
  final _open = <String>{};

  static Iterable<String> _sectionsHolding(String location) => [
    for (final entry in _sectionPages.entries)
      if (entry.value.contains(location)) entry.key,
  ];

  @override
  void initState() {
    super.initState();
    _open.addAll(_sectionsHolding(widget.location));
  }

  @override
  void didUpdateWidget(NavSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The page's own section opens; the sections the member opened stay open.
    if (oldWidget.location != widget.location) {
      _open.addAll(_sectionsHolding(widget.location));
    }
  }

  void _toggle(String id) => setState(() {
    if (!_open.remove(id)) _open.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final club = widget.clubName;
    final sections = [
      _NavSection(
        id: 'rides',
        label: l10n.navRides,
        icon: Icons.directions_bike_outlined,
        pages: [
          (
            path: '/rides',
            label: l10n.navAllRides,
            key: const Key('nav-all-rides'),
          ),
          (
            path: '/club/routes',
            label: l10n.clubRoutesTitle,
            key: const Key('nav-routes'),
          ),
          (path: '/bikes', label: l10n.navBikes, key: const Key('nav-bikes')),
        ],
      ),
      _NavSection(
        id: 'progress',
        label: l10n.navProgress,
        icon: Icons.insights_outlined,
        pages: [
          (
            path: '/progress',
            label: l10n.navOverview,
            key: const Key('nav-overview'),
          ),
          (
            path: '/progress/fitness',
            label: l10n.fitness,
            key: const Key('nav-fitness'),
          ),
          (
            path: '/progress/power',
            label: l10n.metricPower,
            key: const Key('nav-power'),
          ),
          (
            path: '/progress/totals',
            label: l10n.navTotals,
            key: const Key('nav-totals'),
          ),
          (
            path: '/progress/wellbeing',
            label: l10n.wellbeing,
            key: const Key('nav-wellbeing'),
          ),
        ],
      ),
      if (club != null)
        _NavSection(
          id: 'club',
          label: club,
          icon: Icons.groups_outlined,
          pages: [
            (
              path: '/club',
              label: l10n.clubMembers,
              key: const Key('nav-club-members'),
            ),
            (
              path: '/club/rides',
              label: l10n.navClubRides,
              key: const Key('nav-club-rides'),
            ),
            (
              path: '/privacy',
              label: l10n.navSharing,
              key: const Key('nav-sharing'),
            ),
          ],
        ),
    ];
    return Container(
      key: const Key('nav-sidebar'),
      width: AppNav.railExpandedWidth,
      color: scheme.surfaceContainer,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Text(
                'Velomine',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  fontFamily: 'Instrument Serif',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  if (widget.autoTraining)
                    _SidebarLink(
                      key: const Key('sidebar-training'),
                      label: l10n.navTraining,
                      icon: Icons.event_available_outlined,
                      selected:
                          widget.location == '/training' ||
                          widget.location == '/training/setup',
                      onTap: () => context.go('/training'),
                    ),
                  for (final section in sections) ...[
                    _SidebarSection(
                      key: Key('rail-${section.id}'),
                      label: section.label,
                      icon: section.icon,
                      open: _open.contains(section.id),
                      selected: section.pages.any(
                        (page) => page.path == widget.location,
                      ),
                      onTap: () => _toggle(section.id),
                    ),
                    if (_open.contains(section.id))
                      for (final page in section.pages)
                        _SidebarLink(
                          key: page.key,
                          label: page.label,
                          indented: true,
                          selected: page.path == widget.location,
                          onTap: () => context.go(page.path),
                        ),
                    if (section.id == 'progress') ...[
                      _SidebarLink(
                        key: const Key('rail-goals'),
                        label: l10n.navGoals,
                        icon: Icons.flag_outlined,
                        // The events page lives under Goals: it is where an event is added and read.
                        selected:
                            widget.location == '/goals' ||
                            widget.location == '/progress/events',
                        onTap: () => context.go('/goals'),
                      ),
                      if (club == null)
                        _SidebarLink(
                          key: const Key('rail-club'),
                          label: l10n.navGroupClub,
                          icon: Icons.groups_outlined,
                          selected: widget.location == '/join',
                          onTap: () => context.go('/join'),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            const _PrivacyNote(),
            _SidebarLink(
              key: const Key('sidebar-profile'),
              label: l10n.profileTitle,
              icon: Icons.person_outline,
              selected: widget.location == '/profile',
              onTap: () => context.push('/profile'),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const ThemeChoiceButton(),
                  NotificationsButton(
                    unread: widget.unread,
                    selected: widget.location == '/notifications',
                  ),
                  const Spacer(),
                  _AccountMenu(
                    name: widget.name,
                    isAdmin: widget.isAdmin,
                    signedOut: widget.signedOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section of the sidebar: its icon, its name and a chevron that folds its pages away.
class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    super.key,
    required this.label,
    required this.icon,
    required this.open,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool open;

  /// A page inside the section is the one on screen.
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      expanded: open,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      color: selected ? scheme.onPrimaryContainer : null,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: motionDuration(context, AppMotion.standard),
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One page of the sidebar: indented under its section's icon, or a destination of its own.
class _SidebarLink extends StatelessWidget {
  const _SidebarLink({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.indented = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Under a section's icon, a page starts where the section's name does.
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        selected: selected,
        button: true,
        excludeSemantics: true,
        label: label,
        onTap: onTap,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  indented ? AppSpacing.xxl : AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    if (icon case final icon?)
                      Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : null,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The promise under the navigation: a member's data is private until they share it. It points at
/// the privacy screen, which is where they check that.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: InkWell(
        key: const Key('sidebar-privacy'),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: () => context.push('/privacy'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l10n.privacyCardTitle,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.privacyCardBody,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One destination of the collapsed rail: the icon in a pill with the label under it.
class _RailDestination extends StatelessWidget {
  const _RailDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        selected: selected,
        button: true,
        excludeSemantics: true,
        label: label,
        onTap: onTap,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: selected
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    shape: const StadiumBorder(),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    child: icon,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile, admin and signing out, behind the account icon instead of three buttons in the title bar.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({
    required this.name,
    required this.isAdmin,
    required this.signedOut,
    this.avatar = false,
  });

  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  /// A phone shows the member's initial in a circle instead of a generic outline, and carries the
  /// theme inside the menu because the title bar has no room for its own button.
  final bool avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final initial = name?.trim();
    return PopupMenuButton<String>(
      key: const Key('account-menu'),
      tooltip: l10n.accountMenu,
      icon: avatar
          ? CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: initial == null || initial.isEmpty
                  ? Icon(
                      Icons.person_outline,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    )
                  : Text(
                      initial.characters.first.toUpperCase(),
                      style: text.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )
          : const Icon(Icons.account_circle_outlined),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      onSelected: (choice) {
        if (choice.startsWith('theme-')) {
          final mode = ThemeMode.values.firstWhere(
            (m) => m.name == choice.substring('theme-'.length),
          );
          ref.read(themeChoiceViewModelProvider.notifier).choose(mode);
          return;
        }
        switch (choice) {
          case 'profile':
            context.push('/profile');
          case 'admin':
            context.push('/admin');
          case 'feedback':
            ref.read(linkOpenerProvider)(feedbackUrl);
          default:
            signedOut();
        }
      },
      itemBuilder: (context) => [
        if (name != null) ...[
          PopupMenuItem(
            enabled: false,
            child: Text(
              name!,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem(
          key: const Key('account-profile'),
          value: 'profile',
          child: Text(l10n.profileTitle),
        ),
        if (isAdmin)
          PopupMenuItem(
            key: const Key('account-admin'),
            value: 'admin',
            child: Text(l10n.navAdmin),
          ),
        if (avatar) ...[
          const PopupMenuDivider(),
          ..._themeChoices(
            context,
            ref.watch(themeChoiceViewModelProvider).value ?? ThemeMode.system,
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('account-feedback'),
          value: 'feedback',
          child: Text(l10n.sendFeedback),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('account-sign-out'),
          value: 'sign-out',
          child: Text(l10n.signOut),
        ),
      ],
    );
  }
}

/// The project's feedback form on the public site: it reaches whoever builds Velomine, whichever server the member
/// uses, and is anonymous, so the app sends nothing with it.
final feedbackUrl = Uri.parse('https://velomine.eu/feedback/');

/// The three themes, the current one check-marked. They are ordinary menu entries: choosing one
/// sets the theme and closes the menu, the same way the toolbar's own button does.
List<PopupMenuEntry<String>> _themeChoices(
  BuildContext context,
  ThemeMode mode,
) => [
  for (final m in [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
    PopupMenuItem<String>(
      key: Key('theme-${m.name}'),
      value: 'theme-${m.name}',
      child: ListTile(
        leading: Icon(ThemeChoiceButton.iconOf(m)),
        title: Text(ThemeChoiceButton.nameOf(context, m)),
        trailing: m == mode ? const Icon(Icons.check) : null,
        contentPadding: EdgeInsets.zero,
      ),
    ),
];
