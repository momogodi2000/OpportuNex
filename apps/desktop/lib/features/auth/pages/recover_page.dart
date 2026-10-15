import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import 'auth_scaffold.dart';

class RecoverPage extends ConsumerStatefulWidget {
  const RecoverPage({super.key});

  @override
  ConsumerState<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends ConsumerState<RecoverPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phrase = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _phrase, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).recover(
            email: _email.text.trim(),
            phrase: _phrase.text,
            newPassword: _password.text,
            confirmPassword: _confirm.text,
          );
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final api = ref.read(authControllerProvider.notifier);
    return AuthScaffold(
      title: l.authRecoverTitle,
      subtitle: l.authRecoverBody,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.authEmail, prefixIcon: const Icon(Icons.mail_outline)),
              validator: (v) => (v == null || !v.contains('@')) ? l.validationEmail : null,
            ),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _phrase,
              minLines: 2,
              maxLines: 3,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l.authRecoveryPhrase, alignLabelWithHint: true),
              validator: (v) => (v ?? '').trim().split(RegExp(r'\s+')).length != 12 ? l.validationPhraseWords : null,
            ),
            const SizedBox(height: Space.lg),
            PasswordField(
              controller: _password,
              label: l.authNewPassword,
              validator: (v) => (v == null || v.length < 12) ? l.authPasswordHint : null,
            ),
            const SizedBox(height: Space.sm),
            PasswordStrengthMeter(controller: _password, evaluate: (p) => api.passwordStrength(p, [_email.text])),
            const SizedBox(height: Space.lg),
            PasswordField(
              controller: _confirm,
              label: l.authConfirmPassword,
              validator: (v) => v != _password.text ? l.validationPasswordMatch : null,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Space.xl),
            if (_error != null) ...[FormErrorBanner(message: _error!), const SizedBox(height: Space.lg)],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.authRecover),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton(onPressed: () => context.go('/welcome'), child: Text(l.commonBack)),
          ],
        ),
      ),
    );
  }
}
