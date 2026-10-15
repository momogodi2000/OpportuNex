import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? l.commonShow : l.commonHide,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Live strength indicator backed by the engine's zxcvbn + compromised-list check
/// (EF-01.02). [evaluate] returns the engine assessment JSON.
class PasswordStrengthMeter extends StatefulWidget {
  const PasswordStrengthMeter({super.key, required this.controller, required this.evaluate});

  final TextEditingController controller;
  final Future<Map<String, dynamic>> Function(String password) evaluate;

  @override
  State<PasswordStrengthMeter> createState() => _PasswordStrengthMeterState();
}

class _PasswordStrengthMeterState extends State<PasswordStrengthMeter> {
  Timer? _debounce;
  int _score = -1;
  List<String> _problems = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() => _score = -1);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final r = await widget.evaluate(text);
        if (!mounted || widget.controller.text != text) return;
        setState(() {
          _score = (r['score'] as num?)?.toInt() ?? 0;
          _problems = (r['problems'] as List<dynamic>? ?? const []).cast<String>();
        });
      } on Object {
        // Strength is advisory; the engine re-validates on submit.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_score < 0) {
      return Text(l.authPasswordHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant));
    }
    final labels = [l.authStrength0, l.authStrength1, l.authStrength2, l.authStrength3, l.authStrength4];
    final effective = _problems.contains('too_short') || _problems.contains('compromised') ? 0 : _score;
    final color = switch (effective) {
      0 || 1 => context.colors.error,
      2 => Brand.amber,
      _ => Brand.green,
    };
    return Semantics(
      label: labels[effective.clamp(0, 4)],
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: (effective + 1) / 5,
                minHeight: 6,
                color: color,
                backgroundColor: context.colors.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Text(labels[effective.clamp(0, 4)], style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
