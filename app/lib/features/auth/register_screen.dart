import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.session});

  final Session session;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool? _approved; // null until the account is created
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.session.signUp(
      _email.text.trim(),
      _name.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.problem != null) {
        _error = authProblemText(result.problem!);
      } else {
        _approved = result.approved;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final created = _approved != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Create an account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: created
                ? [
                    Text(
                      _approved!
                          ? 'Your account is ready. You can sign in now.'
                          : 'Your account was created. An admin has to approve it before you can sign in.',
                      key: const Key('registered'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Back to sign in'),
                    ),
                  ]
                : [
                    TextField(
                      key: const Key('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('name'),
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        helperText: 'At least 10 characters, with a capital letter, a small letter and a digit.',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        key: const Key('register-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('register'),
                      onPressed: _busy ? null : _register,
                      child: const Text('Create account'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('I already have an account'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
