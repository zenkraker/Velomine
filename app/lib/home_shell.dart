import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/back_guard.dart';
import 'core/l10n.dart';
import 'core/motion.dart';
import 'core/page_actions.dart';
import 'core/providers.dart';
import 'core/theme_choice.dart';
import 'core/tokens.dart';
import 'core/widgets/floating_nav_pill.dart';
import 'core/widgets/page_scaffold.dart';
import 'features/club/club_view_model.dart';
import 'features/notifications/notifications_view_model.dart';
import 'features/recording/live_ride_banner.dart';
import 'features/recording/recording_providers.dart';

/// One tab of the shell: where it goes, its outlined and filled icons and its label.
typedef _Tab = ({String path, Widget icon, Widget selectedIcon, String label});

/// The frame around the signed-in screens. On a phone: three tabs in a floating pill over the page. From
/// 600 dp: the same tabs in a rail. From 1200 dp: a sidebar that holds the brand, the tabs and the
/// account. Every page names itself with its own header, and the shell hands that header the
/// notifications, the account and the way back through a [PageHeaderScope].
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  List<_Tab> _tabs(BuildContext context) => [
    (
      path: '/rides',
      icon: const Icon(Icons.directions_bike_outlined),
      selectedIcon: const Icon(Icons.directions_bike),
      label: context.l10n.navRides,
    ),
    (
      path: '/progress',
      icon: const Icon(Icons.insights_outlined),
      selectedIcon: const Icon(Icons.insights),
      label: context.l10n.navProgress,
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
    // The shell names the screen before the page is built, so a page that is being replaced cannot
    // set the next screen's buttons. After the frame, because a build may not change a provider.
    final current = ref.read(currentLocationProvider);
    if (current != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(currentLocationProvider.notifier).moveTo(location);
        }
      });
    }
    // Until the pages carry their own buttons, a phone tab's filters and import come through here.
    final pageActions = ref.watch(pageActionsProvider);
    final tabs = _tabs(context);
    final pushed = _pushed(tabs);
    // A pushed screen lights no tab.
    final selected = pushed ? -1 : tabs.indexWhere((t) => t.path == location);
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

    // The sidebar carries the notifications and the account itself.
    final page = PageHeaderScope(
      showOnPhone: true,
      onBack: pushed ? () => _back(context) : null,
      trailing: expanded
          ? const []
          : [
              ...pageActions,
              if (!pushed)
                NotificationsButton(
                  unread: unread,
                  selected: location == '/notifications',
                ),
              _AccountMenu(
                name: state.me?.displayName,
                isAdmin: state.isAdmin,
                signedOut: ref.read(sessionProvider).signOut,
                // Below the rail's 600 dp the page header is the only place to stand.
                avatar: !wide,
              ),
            ],
      child: child,
    );

    return BackGuard(
      location: location,
      child: Scaffold(
        body: switch ((expanded, wide)) {
          (true, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(
                tabs: tabs,
                selected: selected < 0 ? null : selected,
                location: location,
                unread: unread,
                name: state.me?.displayName,
                isAdmin: state.isAdmin,
                signedOut: ref.read(sessionProvider).signOut,
              ),
              Expanded(
                child: _WithBanner(banner: banner, child: page),
              ),
            ],
          ),
          (false, true) => Row(
            children: [
              NavigationRail(
                selectedIndex: selected < 0 ? null : selected,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => context.go(tabs[i].path),
                destinations: [
                  for (final tab in tabs)
                    NavigationRailDestination(
                      icon: tab.icon,
                      selectedIcon: tab.selectedIcon,
                      label: Text(tab.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _WithBanner(banner: banner, child: page),
              ),
            ],
          ),
          (false, false) => _PhoneFrame(
            location: location,
            keyboard: keyboard,
            tabs: tabs,
            selected: selected < 0 ? null : selected,
            banner: banner,
            child: page,
          ),
        },
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

/// The notifications button with its unread count, the same in the title bar and the sidebar.
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

/// The desktop frame: the brand, the rider's own tabs and their club, the privacy note, and the
/// person's own controls at the foot.
class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.tabs,
    required this.selected,
    required this.location,
    required this.unread,
    required this.name,
    required this.isAdmin,
    required this.signedOut,
  });

  final List<_Tab> tabs;
  final int? selected;
  final String location;
  final int unread;
  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // The club is the rider's own here, shown by name; the rail and the phone keep their Club tab.
    final club = ref.watch(clubViewModelProvider).club;
    final personal = [
      for (final (i, tab) in tabs.indexed)
        // The club has its own group below.
        if (tab.path != '/club')
          _SidebarDestination(
            icon: i == selected ? tab.selectedIcon : tab.icon,
            label: tab.label,
            selected: i == selected,
            onTap: () => context.go(tab.path),
          ),
    ];
    return Container(
      width: AppLayout.sidebarWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
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
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                Expanded(
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
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _SidebarLabel(group: _SidebarGroup.personal),
                ...personal,
                _SidebarLabel(group: _SidebarGroup.club, top: true),
                if (club == null)
                  _SidebarDestination(
                    icon: const Icon(Icons.groups_outlined),
                    label: l10n.navNoClub,
                    selected: location.startsWith('/club'),
                    onTap: () => context.go('/club'),
                    quiet: true,
                  )
                else
                  _SidebarDestination(
                    avatar: club.name.characters.first.toUpperCase(),
                    label: club.name,
                    selected: location.startsWith('/club'),
                    onTap: () => context.go('/club'),
                  ),
              ],
            ),
          ),
          const _PrivacyNote(),
          const Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const ThemeChoiceButton(),
                NotificationsButton(
                  unread: unread,
                  selected: location == '/notifications',
                ),
                const Spacer(),
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
    );
  }
}

/// The two groups the sidebar is read in: the rider's own tabs, then their club.
enum _SidebarGroup { personal, club }

/// A quiet heading over a group of sidebar entries.
class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({required this.group, this.top = false});

  final _SidebarGroup group;

  /// Room above it, so the second group reads as its own.
  final bool top;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        top ? AppSpacing.xl : AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          group == _SidebarGroup.personal
              ? l10n.navGroupPersonal
              : l10n.navGroupClub,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// One entry of the sidebar: a pill behind the icon and the label when it is the current one. A club
/// shows its initial instead of an icon; a rider without one gets a quieter entry.
class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    this.icon,
    this.avatar,
    this.quiet = false,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : assert(icon != null || avatar != null);

  final Widget? icon;
  final String? avatar;

  /// A destination with nothing to act on yet, such as "No club".
  final bool quiet;
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
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
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
                    if (avatar case final initial?)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: selected
                            ? scheme.onPrimaryContainer
                            : scheme.primaryContainer,
                        foregroundColor: selected
                            ? scheme.primaryContainer
                            : scheme.onPrimaryContainer,
                        child: Text(
                          initial,
                          style: text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? scheme.primaryContainer
                                : scheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    else
                      IconTheme.merge(
                        data: IconThemeData(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        child: icon!,
                      ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : quiet
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
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
          key: const Key('account-sign-out'),
          value: 'sign-out',
          child: Text(l10n.signOut),
        ),
      ],
    );
  }
}

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
