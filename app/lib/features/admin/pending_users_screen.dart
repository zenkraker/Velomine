import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/format.dart';
import '../../core/session.dart';

/// Accounts waiting for an admin to approve them.
class PendingUsersScreen extends StatefulWidget {
  const PendingUsersScreen({super.key, required this.session});

  final Session session;

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  List<UserSummary>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await widget.session.accounts.listUsers(true);
      if (mounted) setState(() => _users = users ?? []);
    } on ApiException catch (e) {
      if (e.code == 401) {
        widget.session.sessionExpired();
      }
      if (mounted) setState(() => _error = 'Could not load the accounts.');
    } on Object {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    }
  }

  Future<void> _approve(UserSummary user) async {
    try {
      await widget.session.accounts.approveUser(user.id);
      if (mounted) {
        setState(() => _users = _users!.where((u) => u.id != user.id).toList());
      }
    } on Object {
      if (mounted) setState(() => _error = 'Could not approve ${user.email}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Waiting for approval',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('admin-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (users == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (users != null && users.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No accounts are waiting for approval.',
              key: Key('none-pending'),
            ),
          ),
        for (final user in users ?? <UserSummary>[])
          Card(
            key: Key('pending-${user.id}'),
            child: ListTile(
              title: Text(user.displayName),
              subtitle: Text('${user.email} · ${dateTime(user.createdAt)}'),
              trailing: FilledButton(
                key: Key('approve-${user.id}'),
                onPressed: () => _approve(user),
                child: const Text('Approve'),
              ),
            ),
          ),
      ],
    );
  }
}
