import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/api/api_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/password_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import 'auth_scaffold.dart';

/// Restore a profile on a new computer from an `.opxbak` backup (EF-18.06).
class ImportProfilePage extends ConsumerStatefulWidget {
  const ImportProfilePage({super.key});

  @override
  ConsumerState<ImportProfilePage> createState() => _ImportProfilePageState();
}

class _ImportProfilePageState extends ConsumerState<ImportProfilePage> {
  final _password = TextEditingController();
  String? _file;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['opxbak']);
    final path = r?.files.single.path;
    if (path != null) setState(() => _file = path);
  }

  Future<void> _import() async {
    final api = ref.read(apiClientProvider);
    if (api == null || _file == null || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await File(_file!).readAsBytes();
      final profile = await api.upload('/auth/profiles/import',
          fileName: p.basename(_file!), bytes: bytes, fields: {'password': _password.text});
      await ref.read(authControllerProvider.notifier).unlock(profile['id'] as String, _password.text);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authImportProfile,
      subtitle: l.importProfileBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(_file == null ? l.importChooseFile : p.basename(_file!)),
          ),
          const SizedBox(height: Space.lg),
          PasswordField(controller: _password, label: l.authPassword, onSubmitted: (_) => _import()),
          const SizedBox(height: Space.xl),
          if (_error != null) ...[FormErrorBanner(message: _error!), const SizedBox(height: Space.lg)],
          FilledButton(
            onPressed: _busy || _file == null ? null : _import,
            child: _busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.importAction),
          ),
          const SizedBox(height: Space.md),
          OutlinedButton(onPressed: () => context.go('/welcome'), child: Text(l.commonBack)),
        ],
      ),
    );
  }
}
