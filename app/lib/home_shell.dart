import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/back_guard.dart';
import 'core/l10n.dart';
import 'core/page_actions.dart';
import 'core/providers.dart';
import 'core/session.dart';
import 'core/theme_choice.dart';
import 'core/tokens.dart';
import 'features/club/club_view_model.dart';
import 'features/notifications/notifications_view_model.dart';
import 'features/recording/recording_providers.dart';

/// One tab of the shell: where it goes, its icon and its label.
typedef _Tab = ({String path, Widget icon, String label});

/// The frame around the signed-in screens. On a phone: a title bar and at most five tabs in a bottom
/// bar. From 600 dp: the same tabs in a rail. From 1200 dp: a sidebar that holds the brand, the tabs
/// and the account, and the page names itself — the width a desktop window has is for the page, not
/// for a stretched phone column.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  List<_Tab> _tabs(BuildContext context, String recording) => [
    (
      path: '/rides',
      icon: const Icon(Icons.directions_bike),
      label: context.l10n.navRides,
    ),
    if (!kIsWeb)
      (
        path: '/record',
        icon: switch (recording) {
          'recording' => Badge(
            child: Icon(
              Icons.fiber_smart_record,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          'paused' => const Icon(Icons.pause_circle_outline),
          _ => const Icon(Icons.fiber_manual_record),
        },
        label: context.l10n.navRecord,
      ),
    (
      path: '/progress',
      icon: const Icon(Icons.insights),
      label: context.l10n.navProgress,
    ),
    (
      path: '/club',
      icon: const Icon(Icons.groups_outlined),
      label: context.l10n.navClub,
    ),
    (
      path: '/bikes',
      icon: const Icon(Icons.pedal_bike),
      label: context.l10n.navBikes,
    ),
  ];

  /// The name of the screen the person is on; the brand only where nothing else fits. A specific
  /// screen is named before the tab it was opened from, so a ride does not read "Rides".
  String _title(BuildContext context) {
    final l10n = context.l10n;
    final path = location;
    if (path.startsWith('/rides/import')) return l10n.importTitle;
    if (_rideId.hasMatch(path)) return l10n.rideDetailTitle;
    if (path.startsWith('/rides')) return l10n.navRides;
    if (path.startsWith('/record')) return l10n.navRecord;
    if (path.startsWith('/progress')) return l10n.navProgress;
    if (path.startsWith('/bikes')) return l10n.navBikes;
    if (path.startsWith('/club/athletes')) return l10n.athletesTitle;
    if (path.startsWith('/club/rides')) return l10n.clubRidesTitle;
    if (path.startsWith('/club/routes')) return l10n.clubRoutesTitle;
    if (path.startsWith('/club/calendar')) return l10n.calendarTitle;
    if (path.startsWith('/club')) return l10n.navClub;
    if (path.startsWith('/join')) return l10n.joinTitle;
    if (path.startsWith('/profile/two-factor')) return l10n.twoFactorNavTitle;
    if (path.startsWith('/profile/sessions')) return l10n.sessionsNavTitle;
    if (path.startsWith('/profile/supporter')) return l10n.supporterSignInTitle;
    if (path.startsWith('/profile')) return l10n.profileTitle;
    if (path.startsWith('/privacy')) return l10n.privacyTitle;
    if (path.startsWith('/notifications')) return l10n.notifications;
    if (path.startsWith('/admin')) return l10n.navAdmin;
    return 'Velomine';
  }

  static final _rideId = RegExp(r'^/rides/[^/]+$');

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
    final recording = ref.watch(recorderSnapshotViewModelProvider).state;
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
    // The tab's own title-bar buttons, empty on a wide window where the page has its header.
    final pageActions = ref.watch(pageActionsProvider);
    final tabs = _tabs(context, recording);
    final selected = tabs.indexWhere((tab) => location.startsWith(tab.path));
    final pushed = _pushed(tabs);
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= AppBreakpoint.expandedWidth;
    final wide = width >= AppBreakpoint.compactWidth;

    return BackGuard(
      location: location,
      child: Scaffold(
        // A blank page on a wide window, where the page brings its own header.
        appBar: expanded
            ? null
            : _appBar(
                context,
                state,
                unread,
                pushed,
                ref.read(sessionProvider).signOut,
                pageActions,
              ),
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
                // A pushed screen has no title bar here, so the sidebar carries its way back.
                onBack: pushed ? () => _back(context) : null,
              ),
              Expanded(child: child),
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
                      label: Text(tab.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
          (false, false) => child,
        },
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                // A screen that is not a tab lights none of them: the bar needs an index, so it keeps
                // the first one with its highlight hidden.
                selectedIndex: selected < 0 ? 0 : selected,
                indicatorColor: selected < 0 ? Colors.transparent : null,
                onDestinationSelected: (i) => context.go(tabs[i].path),
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(icon: tab.icon, label: tab.label),
                ],
              ),
      ),
    );
  }

  /// The phone's title bar: it names the screen, offers the way back and the account, and keeps its
  /// surface so a list does not read as sliding under it.
  AppBar _appBar(
    BuildContext context,
    SessionState state,
    int unread,
    bool pushed,
    VoidCallback signedOut,
    List<Widget> pageActions,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      // The shell decides: an automatic back arrow would appear on a tab after a push.
      automaticallyImplyLeading: false,
      title: Text(_title(context)),
      leading: pushed ? BackButton(onPressed: () => _back(context)) : null,
      // A pushed screen keeps its back arrow and the account; the notifications stay on the tabs'
      // bars. A phone has no room for a third icon beside the filters, so the theme moves into the
      // account menu; a rail keeps its own theme button.
      actions: [
        // The page's own controls first, then the ones every tab has.
        ...pageActions,
        if (!pushed)
          NotificationsButton(
            unread: unread,
            selected: location == '/notifications',
          ),
        _AccountMenu(
          name: state.me?.displayName,
          isAdmin: state.isAdmin,
          signedOut: signedOut,
          // Below the rail's 600 dp the title bar is the only place to stand.
          avatar: MediaQuery.sizeOf(context).width < AppBreakpoint.compactWidth,
        ),
      ],
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    );
  }
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
    this.onBack,
  });

  final List<_Tab> tabs;
  final int? selected;
  final String location;
  final int unread;
  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  /// The way back to the tab, on a screen that was pushed over one.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // The club is the rider's own here, shown by name; the rail and the phone keep their Club tab.
    final club = ref.watch(clubViewModelProvider).club;
    final personal = [
      for (final (i, tab) in tabs.indexed)
        // Recording is a phone job; the club has its own group below.
        if (tab.path != '/club' && tab.path != '/record')
          _SidebarDestination(
            icon: tab.icon,
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
                if (onBack case final back?) BackButton(onPressed: back),
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
