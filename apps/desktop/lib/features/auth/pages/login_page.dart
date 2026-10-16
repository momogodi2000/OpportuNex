import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import '../auth_models.dart';
import 'auth_scaffold.dart';

/// Sign in by e-mail, or unlock a known profile (`?profile=<id>`, or the locked one).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.profileId});
  final String? profileId;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String? profileId) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (profileId != null) {
        await auth.unlock(profileId, _password.text);
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final locked = auth is LockedOut ? auth : null;
    final profiles = switch (auth) {
      SignedOut(:final profiles) => profiles,
      LockedOut(:final profiles) => profiles,
      _ => const <LocalProfile>[],
    };
    final profileId = widget.profileId ?? locked?.profileId;
    final profile = profiles.where((p) => p.id == profileId).firstOrNull;
    final unlocking = locked != null && locked.profileId == profileId;

    final title = unlocking ? l.authUnlockTitle : (profile?.displayName ?? l.authSignInTitle);
    final subtitle = switch (unlocking ? locked.reason : null) {
      'inactivity' => l.authUnlockInactivity,
      'expired' => l.authUnlockExpired,
      String() => l.authUnlockManual,
      null => null,
    };

    return AuthScaffold(
      title: title,
      subtitle: subtitle,
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (profile == null) ...[
                TextFormField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.authEmail, prefixIcon: const Icon(Icons.mail_outline)),
                  validator: (v) => (v == null || !v.contains('@')) ? l.validationEmail : null,
                ),
                const SizedBox(height: Space.lg),
              ],
              PasswordField(
                controller: _password,
                label: l.authPassword,
                autofocus: profile != null,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.isEmpty) ? l.validationRequired : null,
                onSubmitted: (_) => _submit(profile?.id),
              ),
              const SizedBox(height: Space.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => context.go('/recover'), child: Text(l.authForgotPassword)),
              ),
              if (_error != null) ...[FormErrorBanner(message: _error!), const SizedBox(height: Space.lg)],
              FilledButton(
                onPressed: _busy ? null : () => _submit(profile?.id),
                child: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(unlocking ? l.authUnlock : l.authSignIn),
              ),
              const SizedBox(height: Space.md),
              OutlinedButton(
                onPressed: () => context.go('/welcome'),
                child: Text(unlocking ? l.authSwitchProfile : l.commonBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
