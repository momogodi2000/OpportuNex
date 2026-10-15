import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/prefs/ui_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/password_field.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import 'about_section.dart';
import 'maintenance_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, 0),
            child: Semantics(header: true, child: Text(l.navSettings, style: context.text.headlineSmall)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l.settingsAccount),
                Tab(text: l.settingsBackups),
                Tab(text: l.settingsMaintenance),
                Tab(text: l.settingsAbout),
              ],
            ),
          ),
          const Divider(),
          const Expanded(
            child: TabBarView(children: [
              _AccountTab(),
              _BackupsTab(),
              _MaintenanceTab(),
              AboutSection(),
            ]),
          ),
        ],
      ),
    );
  }
}

Widget _tabBody(List<Widget> children) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(Space.xxl),
          children: [for (final c in children) Padding(padding: const EdgeInsets.only(bottom: Space.xl), child: c)],
        ),
      ),
    );

// ---------------------------------------------------------------- account
class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    if (auth is! SignedIn) return const LoadingState();
    final user = auth.user;
    final ctrl = ref.read(authControllerProvider.notifier);

    Future<void> update(Future<void> Function() action) async {
      try {
        await action();
        if (context.mounted) showSuccess(context, l.settingsSaved);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return _tabBody([
      SectionCard(
        title: l.settingsProfileSection,
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: Text(user.displayName),
            subtitle: Text(user.email),
            trailing: TextButton(
              onPressed: () async {
                final name = await _askText(context, l.authDisplayName, user.displayName);
                if (name != null && name.trim().isNotEmpty) {
                  await update(() => ctrl.updatePreferences(displayName: name.trim()));
                }
              },
              child: Text(l.commonEdit),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(user.isSynced ? Icons.cloud_done_outlined : Icons.computer),
            title: Text(user.isSynced ? l.authModeSynced : l.authModeLocal),
            subtitle: Text(user.isSynced ? l.settingsModeSyncedHelp : l.settingsModeLocalHelp),
          ),
        ]),
      ),
      SectionCard(
        title: l.settingsAppearance,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.authLanguage, style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {user.locale},
            onSelectionChanged: (s) => update(() => ctrl.updatePreferences(locale: s.first)),
          ),
          const SizedBox(height: Space.lg),
          Text(l.settingsTheme, style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', icon: const Icon(Icons.brightness_auto), label: Text(l.settingsThemeSystem)),
              ButtonSegment(value: 'light', icon: const Icon(Icons.light_mode_outlined), label: Text(l.settingsThemeLight)),
              ButtonSegment(value: 'dark', icon: const Icon(Icons.dark_mode_outlined), label: Text(l.settingsThemeDark)),
            ],
            selected: {themeModeName(ref.watch(uiPrefsProvider).themeMode)},
            onSelectionChanged: (s) => update(() => ctrl.updatePreferences(theme: s.first)),
          ),
        ]),
      ),
      SectionCard(
        title: l.settingsSecurity,
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.settingsAutoLock),
            subtitle: Text(l.settingsAutoLockHelp),
            trailing: DropdownButton<int>(
              value: const [5, 10, 15, 30, 60, 120, 240].contains(user.autoLockMinutes) ? user.autoLockMinutes : 15,
              items: [
                for (final m in const [5, 10, 15, 30, 60, 120, 240])
                  DropdownMenuItem(value: m, child: Text(l.settingsMinutes(m))),
              ],
              onChanged: (m) => m == null ? null : update(() => ctrl.updatePreferences(autoLockMinutes: m)),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password),
            title: Text(l.settingsChangePassword),
            subtitle: Text(l.settingsChangePasswordHelp),
            trailing: OutlinedButton(
              onPressed: () => showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog()),
              child: Text(l.commonEdit),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: Text(l.authLock),
            subtitle: const Text('Ctrl+L'),
            trailing: OutlinedButton(onPressed: ctrl.lock, child: Text(l.authLock)),
          ),
        ]),
      ),
      SectionCard(
        title: l.settingsDangerZone,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
          title: Text(l.settingsDeleteAccount),
          subtitle: Text(l.settingsDeleteAccountHelp),
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: context.colors.error),
            onPressed: () => _deleteAccount(context, ref),
            child: Text(l.commonDelete),
          ),
        ),
      ),
    ]);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l.settingsDeleteAccount,
      message: l.settingsDeleteAccountConfirm,
      confirmLabel: l.commonDelete,
      destructive: true,
      typedWord: 'DELETE',
    );
    if (!ok || !context.mounted) return;
    final password = await _askPassword(context);
    if (password == null || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(password);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

Future<String?> _askText(BuildContext context, String label, String initial) {
  final c = TextEditingController(text: initial);
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(label),
      content: TextField(controller: c, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.commonSave)),
      ],
    ),
  ).whenComplete(c.dispose);
}

Future<String?> _askPassword(BuildContext context) {
  final c = TextEditingController();
  final l = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.settingsConfirmWithPassword),
      content: SizedBox(
        width: 400,
        child: PasswordField(controller: c, label: l.authPassword, autofocus: true, onSubmitted: (v) => Navigator.pop(ctx, v)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.commonConfirm)),
      ],
    ),
  ).whenComplete(c.dispose);
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(_current.text, _next.text, _confirm.text);
      if (mounted) {
        Navigator.pop(context);
        showSuccess(context, l.settingsPasswordChanged);
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(authControllerProvider.notifier);
    return AlertDialog(
      title: Text(l.settingsChangePassword),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            PasswordField(controller: _current, label: l.settingsCurrentPassword, autofocus: true,
                validator: (v) => (v ?? '').isEmpty ? l.validationRequired : null),
            const SizedBox(height: Space.lg),
            PasswordField(controller: _next, label: l.authNewPassword,
                validator: (v) => (v ?? '').length < 12 ? l.authPasswordHint : null),
            const SizedBox(height: Space.sm),
            PasswordStrengthMeter(controller: _next, evaluate: (p) => ctrl.passwordStrength(p, const [])),
            const SizedBox(height: Space.lg),
            PasswordField(controller: _confirm, label: l.authConfirmPassword,
                validator: (v) => v != _next.text ? l.validationPasswordMatch : null, onSubmitted: (_) => _save()),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l.commonSave)),
      ],
    );
  }
}

// ---------------------------------------------------------------- backups
class _BackupsTab extends ConsumerWidget {
  const _BackupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(backupsProvider);
    final repo = ref.read(maintenanceRepositoryProvider);
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm();

    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        ref.invalidate(backupsProvider);
        if (context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return AsyncView<BackupOverview>(
      value: value,
      onRetry: () => ref.invalidate(backupsProvider),
      data: (o) => _tabBody([
        SectionCard(
          title: l.backupsTitle,
          subtitle: l.backupsHelp,
          trailing: FilledButton.icon(
            onPressed: () => run(repo.createBackup, l.backupsCreated),
            icon: const Icon(Icons.backup_outlined),
            label: Text(l.backupsCreate),
          ),
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: o.autoEnabled,
              onChanged: (v) => run(() => repo.setAutoBackup(v), l.settingsSaved),
              title: Text(l.backupsAuto),
              subtitle: Text(l.backupsAutoHelp),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: Text(l.backupsFolder),
              subtitle: SelectableText(o.directory),
            ),
          ]),
        ),
        SectionCard(
          title: l.backupsHistory,
          child: o.items.isEmpty
              ? EmptyState(icon: Icons.inventory_2_outlined, title: l.backupsEmpty)
              : Column(children: [
                  for (final b in o.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(b.available ? Icons.archive_outlined : Icons.report_problem_outlined,
                          color: b.available ? null : context.colors.error),
                      title: Text('${fmt.format(b.createdAt)} · ${_kindLabel(l, b.kind)}'),
                      subtitle: Text('${_size(b.sizeBytes)} · ${b.status == 'restored' ? l.backupsRestoredTag : l.backupsOkTag}'),
                      trailing: Wrap(spacing: Space.xs, children: [
                        IconButton(
                          tooltip: l.backupsVerify,
                          icon: const Icon(Icons.verified_outlined),
                          onPressed: b.available ? () => run(() => repo.verify(b.id), l.backupsVerified) : null,
                        ),
                        IconButton(
                          tooltip: l.backupsRestore,
                          icon: const Icon(Icons.settings_backup_restore),
                          onPressed: b.available ? () => _restore(context, ref, b) : null,
                        ),
                        IconButton(
                          tooltip: l.commonDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await confirmAction(context,
                                title: l.backupsDelete, message: l.backupsDeleteConfirm,
                                confirmLabel: l.commonDelete, destructive: true);
                            if (ok) await run(() => repo.delete(b.id), l.backupsDeleted);
                          },
                        ),
                      ]),
                    ),
                ]),
        ),
      ]),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, BackupInfo b) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmAction(context,
        title: l.backupsRestore, message: l.backupsRestoreConfirm, confirmLabel: l.backupsRestore,
        destructive: true, typedWord: 'RESTORE');
    if (!ok || !context.mounted) return;
    final password = await _askPassword(context);
    if (password == null || !context.mounted) return;
    try {
      await ref.read(maintenanceRepositoryProvider).restore(b.id, password);
      ref.invalidate(backupsProvider);
      if (context.mounted) showSuccess(context, l.backupsRestored);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

String _kindLabel(AppLocalizations l, String kind) => switch (kind) {
      'manual' => l.backupKindManual,
      'scheduled' => l.backupKindScheduled,
      'pre_migration' => l.backupKindPreMigration,
      'pre_restore' => l.backupKindPreRestore,
      _ => kind,
    };

String _size(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} Mo';
}

// ------------------------------------------------------------- maintenance
class _MaintenanceTab extends ConsumerWidget {
  const _MaintenanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(maintenanceRepositoryProvider);
    final storage = ref.watch(storageProvider);

    Future<void> run(Future<Object?> Function() action, String done) async {
      try {
        await action();
        ref.invalidate(storageProvider);
        if (context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return _tabBody([
      SectionCard(
        title: l.maintenanceStorage,
        child: AsyncView(
          value: storage,
          data: (s) => Column(children: [
            _kv(context, l.maintenanceDatabase, _size((s['database_bytes'] as num).toInt())),
            _kv(context, l.maintenanceVault, _size((s['vault_bytes'] as num).toInt())),
            _kv(context, l.backupsTitle, _size((s['backups_bytes'] as num).toInt())),
            _kv(context, l.maintenanceDataDir, s['data_dir'] as String),
          ]),
        ),
      ),
      SectionCard(
        title: l.maintenanceTools,
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(l.maintenanceIntegrity),
            subtitle: Text(l.maintenanceIntegrityHelp),
            trailing: OutlinedButton(onPressed: () => run(repo.integrity, l.maintenanceIntegrityOk), child: Text(l.maintenanceRun)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.speed),
            title: Text(l.maintenanceOptimize),
            subtitle: Text(l.maintenanceOptimizeHelp),
            trailing: OutlinedButton(onPressed: () => run(repo.optimize, l.maintenanceOptimized), child: Text(l.maintenanceRun)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(l.maintenanceLogs),
            subtitle: Text(l.maintenanceLogsHelp),
            trailing: OutlinedButton(
              onPressed: () async {
                final target = await FilePicker.platform.saveFile(fileName: 'opportunex-logs.zip');
                if (target == null) return;
                await run(() async => File(target).writeAsBytes(await repo.logs()), l.maintenanceLogsSaved);
              },
              child: Text(l.maintenanceExport),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(children: [
          SizedBox(width: 220, child: Text(k, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))),
          Expanded(child: SelectableText(v)),
        ]),
      );
}
