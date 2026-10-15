import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'error_text.dart';

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(errorText(context, error)),
      backgroundColor: context.colors.errorContainer,
      showCloseIcon: true,
      closeIconColor: context.colors.onErrorContainer,
    ));
}

/// Confirmation for sensitive operations. With [typedWord], the user must type it
/// (e.g. "DELETE") before the destructive button is enabled.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? typedWord,
}) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final enabled = typedWord == null || controller.text.trim() == typedWord;
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (typedWord != null) ...[
                  const SizedBox(height: Space.lg),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(labelText: typedWord),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: ctx.colors.error,
                      foregroundColor: ctx.colors.onError,
                    )
                  : null,
              onPressed: enabled ? () => Navigator.pop(ctx, true) : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return ok ?? false;
}
