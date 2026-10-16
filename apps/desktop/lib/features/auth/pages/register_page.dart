import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/prefs/ui_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import '../auth_models.dart';
import 'auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accept = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    if (!_accept) {
      setState(() => _error = l.errTermsNotAccepted);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            displayName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            confirmPassword: _confirm.text,
            locale: ref.read(uiPrefsProvider).locale.languageCode,
            acceptTerms: _accept,
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
    final auth = ref.watch(authControllerProvider);
    if (auth is SignedIn && auth.recoveryPhrase != null) {
      return RecoveryPhrasePage(phrase: auth.recoveryPhrase!);
    }
    final api = ref.read(authControllerProvider.notifier);
    return AuthScaffold(
      title: l.authRegisterTitle,
      subtitle: l.authRegisterSubtitle,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.authDisplayName, prefixIcon: const Icon(Icons.badge_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l.validationRequired : null,
            ),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l.authEmail, prefixIcon: const Icon(Icons.mail_outline)),
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
                  ? l.validationEmail
                  : null,
            ),
            const SizedBox(height: Space.lg),
            PasswordField(
              controller: _password,
              label: l.authPassword,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.length < 12) ? l.authPasswordHint : null,
            ),
            const SizedBox(height: Space.sm),
            PasswordStrengthMeter(
              controller: _password,
              evaluate: (p) => api.passwordStrength(p, [_name.text, _email.text]),
            ),
            const SizedBox(height: Space.lg),
            PasswordField(
              controller: _confirm,
              label: l.authConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? l.validationPasswordMatch : null,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Space.md),
            CheckboxListTile(
              value: _accept,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _accept = v ?? false),
              title: Text(l.authAcceptTerms),
              subtitle: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => context.push('/legal'), child: Text(l.authReadTerms)),
              ),
            ),
            const SizedBox(height: Space.md),
            if (_error != null) ...[FormErrorBanner(message: _error!), const SizedBox(height: Space.lg)],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.authCreateAccount),
            ),
            const SizedBox(height: Space.md),
            TextButton(onPressed: () => context.go('/welcome'), child: Text(l.authAlreadyHaveAccount)),
          ],
        ),
      ),
    );
  }
}

/// One-time display of the 12-word recovery phrase (EF-01.06).
class RecoveryPhrasePage extends ConsumerStatefulWidget {
  const RecoveryPhrasePage({super.key, required this.phrase});
  final String phrase;

  @override
  ConsumerState<RecoveryPhrasePage> createState() => _RecoveryPhrasePageState();
}

class _RecoveryPhrasePageState extends ConsumerState<RecoveryPhrasePage> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final words = widget.phrase.split(' ');
    return AuthScaffold(
      title: l.authPhraseTitle,
      subtitle: l.authPhraseBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: context.status.warning,
              borderRadius: Radii.card,
            ),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.6,
              mainAxisSpacing: Space.sm,
              crossAxisSpacing: Space.sm,
              children: [
                for (var i = 0; i < words.length; i++)
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    decoration: BoxDecoration(color: context.colors.surface, borderRadius: Radii.control),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '${i + 1}. ', style: TextStyle(color: context.colors.onSurfaceVariant)),
                      TextSpan(text: words[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                    ])),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.phrase));
                if (context.mounted) showSuccess(context, l.commonCopied);
              },
              icon: const Icon(Icons.copy),
              label: Text(l.commonCopy),
            ),
          ),
          CheckboxListTile(
            value: _confirmed,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            title: Text(l.authPhraseConfirm),
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _confirmed
                ? () async {
                    await Clipboard.setData(const ClipboardData(text: ''));
                    ref.read(authControllerProvider.notifier).acknowledgeRecoveryPhrase();
                  }
                : null,
            child: Text(l.commonContinue),
          ),
        ],
      ),
    );
  }
}
