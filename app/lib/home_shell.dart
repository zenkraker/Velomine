import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/back_guard.dart';
import 'core/l10n.dart';
import 'core/providers.dart';
import 'core/theme_choice.dart';
import 'core/tokens.dart';
import 'features/notifications/notifications_view_model.dart';
import 'features/recording/recording_providers.dart';

/// One tab of the shell: where it goes, its icon and its label.
typedef _Tab = ({String path, Widget icon, String label});

/// The frame around the signed-in screens: a title bar that names the screen, the account menu and
/// notifications, and at most five tabs — a bar on a phone, a rail from 600 dp up.
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

  /// The name of the screen the person is on; the brand only where nothing else fits.
  String _title(BuildContext context) {
    final l10n = context.l10n;
    final path = location;
    if (path.startsWith('/rides/import')) return l10n.importTitle;
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
    if (path.startsWith('/profile')) return l10n.profileTitle;
    if (path.startsWith('/privacy')) return l10n.privacyTitle;
    if (path.startsWith('/notifications')) return l10n.notifications;
    if (path.startsWith('/admin')) return l10n.navAdmin;
    return 'Velomine';
  }

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
    final tabs = _tabs(context, recording);
    final selected = tabs.indexWhere((tab) => location.startsWith(tab.path));
    final pushed = _pushed(tabs);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return BackGuard(
      location: location,
      child: Scaffold(
        appBar: AppBar(
          // The shell decides: an automatic back arrow would appear on a tab after a push.
          automaticallyImplyLeading: false,
          title: Text(_title(context)),
          leading: pushed ? BackButton(onPressed: () => _back(context)) : null,
          // A pushed screen keeps its title readable: the global actions stay on the tabs' bars.
          actions: [
            if (!pushed) ...[
              const ThemeChoiceButton(),
              IconButton(
                key: const Key('open-notifications'),
                tooltip: unread == 0
                    ? context.l10n.notifications
                    : context.l10n.notificationsUnread(unread),
                isSelected: location == '/notifications',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none),
                ),
                onPressed: () => context.push('/notifications'),
              ),
            ],
            _AccountMenu(
              name: state.me?.displayName,
              isAdmin: state.isAdmin,
              signedOut: ref.read(sessionProvider).signOut,
            ),
          ],
        ),
        body: wide
            ? Row(
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
              )
            : child,
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
}

/// Profile, admin and signing out, behind the account icon instead of three buttons in the title bar.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.name,
    required this.isAdmin,
    required this.signedOut,
  });

  final String? name;
  final bool isAdmin;
  final VoidCallback signedOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return PopupMenuButton<String>(
      key: const Key('account-menu'),
      tooltip: l10n.accountMenu,
      icon: const Icon(Icons.account_circle_outlined),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      onSelected: (choice) => switch (choice) {
        'profile' => context.push('/profile'),
        'admin' => context.push('/admin'),
        _ => signedOut(),
      },
      itemBuilder: (context) => [
        if (name != null) ...[
          PopupMenuItem(
            enabled: false,
            child: Text(
              name!,
              style: text.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
        PopupMenuItem(
          key: const Key('account-sign-out'),
          value: 'sign-out',
          child: Text(l10n.signOut),
        ),
      ],
    );
  }
}
