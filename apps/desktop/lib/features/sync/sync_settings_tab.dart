import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/password_field.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'sync_repository.dart';

/// Settings > Sync (EF-01.09/10/12, M17): optional, end-to-end encrypted, self-hosted server.
class SyncSettingsTab extends ConsumerWidget {
  const SyncSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<Json>(
      value: ref.watch(syncStatusProvider),
      onRetry: () => ref.invalidate(syncStatusProvider),
      data: (s) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(padding: const EdgeInsets.all(Space.xxl), children: [
            if (!s.flag('linked')) const _NotLinked() else ...[
              _Linked(status: s),
              if (!s.flag('paired')) ...[const SizedBox(height: Space.xl), _Pending(status: s)],
              if (s.flag('paired')) ...[
                const SizedBox(height: Space.xl),
                const _Devices(),
                if ((s.integer('conflicts') ?? 0) > 0) ...[const SizedBox(height: Space.xl), const _Conflicts()],
                const SizedBox(height: Space.xl),
                const _Security(),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

Future<void> _act(BuildContext context, WidgetRef ref, Future<Object?> Function() fn, [String? done]) async {
  try {
    await fn();
    ref
      ..invalidate(syncStatusProvider)
      ..invalidate(syncDevicesProvider)
      ..invalidate(syncConflictsProvider)
      ..invalidate(orgsProvider);
    // Linking, unlinking or deleting the online account changes the mode shown in the sidebar (EF-01.12).
    await ref.read(authControllerProvider.notifier).refresh();
    if (done != null && context.mounted) showSuccess(context, done);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class _NotLinked extends ConsumerStatefulWidget {
  const _NotLinked();

  @override
  ConsumerState<_NotLinked> createState() => _NotLinkedState();
}

class _NotLinkedState extends ConsumerState<_NotLinked> {
  final _server = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _totp = TextEditingController();
  String _mode = 'link'; // link | create | verify | reset
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_server, _email, _password, _code, _totp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _go(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final server = _server.text.trim();
    final email = _email.text.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: l.syncTitle,
        subtitle: l.syncLocalMode,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final line in [l.syncRule1, l.syncRule2, l.syncRule3])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lock_outline, size: 18, color: context.colors.primary),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(line, style: context.text.bodySmall)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: Space.xl),
      SectionCard(
        title: switch (_mode) {
          'create' => l.syncCreate,
          'verify' => l.syncVerifyTitle,
          'reset' => l.syncResetTitle,
          _ => l.syncLink,
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _server,
            decoration: InputDecoration(labelText: l.syncServer, hintText: 'https://sync.example.org', helperText: l.syncServerHelp),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          if (_mode != 'verify')
            TextField(controller: _email, decoration: InputDecoration(labelText: l.authEmail), onChanged: (_) => setState(() {})),
          if (_mode == 'link' || _mode == 'create') ...[
            const SizedBox(height: Space.md),
            PasswordField(controller: _password, label: l.syncOnlinePassword),
          ],
          if (_mode == 'link') ...[
            const SizedBox(height: Space.md),
            TextField(controller: _totp, decoration: InputDecoration(labelText: l.syncTotpOptional), keyboardType: TextInputType.number),
          ],
          if (_mode == 'verify' || _mode == 'reset') ...[
            const SizedBox(height: Space.md),
            TextField(controller: _code, decoration: InputDecoration(labelText: l.syncEmailCode, helperText: l.syncEmailCodeHelp)),
          ],
          if (_mode == 'reset') ...[
            const SizedBox(height: Space.md),
            PasswordField(controller: _password, label: l.syncNewPassword),
            const SizedBox(height: Space.sm),
            Text(l.syncResetWarning, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
          const SizedBox(height: Space.lg),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, alignment: WrapAlignment.end, children: [
            if (_mode == 'link') ...[
              TextButton(onPressed: () => setState(() => _mode = 'reset'), child: Text(l.syncForgot)),
              TextButton(onPressed: () => setState(() => _mode = 'create'), child: Text(l.syncCreate)),
              FilledButton(
                onPressed: _busy || server.isEmpty || email.isEmpty ? null : () => _go(() async {
                  await repo.link(server, email, _password.text,
                      totp: _totp.text.trim().isEmpty ? null : _totp.text.trim());
                  if (context.mounted) await _act(context, ref, () async => null, l.syncLinked);
                }),
                child: Text(l.syncLink),
              ),
            ],
            if (_mode == 'create') ...[
              TextButton(onPressed: () => setState(() => _mode = 'link'), child: Text(l.commonBack)),
              FilledButton(
                onPressed: _busy || server.isEmpty || email.isEmpty ? null : () => _go(() async {
                  await repo.register(server, email, _password.text);
                  if (mounted) setState(() => _mode = 'verify');
                }),
                child: Text(l.syncCreate),
              ),
            ],
            if (_mode == 'verify') ...[
              TextButton(onPressed: () => _go(() => repo.resend(server, email)), child: Text(l.syncResend)),
              FilledButton(
                onPressed: _busy ? null : () => _go(() async {
                  await repo.verify(server, _code.text.trim());
                  await repo.link(server, email, _password.text);
                  if (context.mounted) await _act(context, ref, () async => null, l.syncLinked);
                }),
                child: Text(l.syncVerifyAndLink),
              ),
            ],
            if (_mode == 'reset') ...[
              TextButton(onPressed: () => setState(() => _mode = 'link'), child: Text(l.commonBack)),
              OutlinedButton(
                onPressed: _busy || server.isEmpty || email.isEmpty ? null : () => _go(() async {
                  await repo.resetRequest(server, email);
                  if (context.mounted) showSuccess(context, l.syncCodeSent);
                }),
                child: Text(l.syncSendCode),
              ),
              FilledButton(
                onPressed: _busy ? null : () => _go(() async {
                  await repo.reset(server, _code.text.trim(), _password.text);
                  if (context.mounted) {
                    showSuccess(context, l.syncPasswordReset);
                    setState(() => _mode = 'link');
                  }
                }),
                child: Text(l.syncResetTitle),
              ),
            ],
          ]),
        ]),
      ),
    ]);
  }
}

class _Linked extends ConsumerWidget {
  const _Linked({required this.status});
  final Json status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final s = status;
    return SectionCard(
      title: l.syncTitle,
      subtitle: l.syncSyncedMode(s.string('email')),
      trailing: FilledButton.icon(
        onPressed: s.flag('paired') ? () => _act(context, ref, repo.run, l.syncDone) : null,
        icon: const Icon(Icons.sync),
        label: Text(l.syncNow),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l.syncServer} : ${s.string('server_url')}'),
        Text(l.syncLast(Fmt.dateTime(context, s.str('last_pull_at')))),
        Text(l.syncPending(s.integer('pending_changes') ?? 0)),
        const SizedBox(height: Space.md),
        TextButton.icon(
          icon: const Icon(Icons.link_off),
          label: Text(l.syncUnlink),
          onPressed: () async {
            final ok = await confirmAction(context, title: l.syncUnlink, message: l.syncUnlinkConfirm, confirmLabel: l.syncUnlink);
            if (ok && context.mounted) await _act(context, ref, repo.unlink);
          },
        ),
      ]),
    );
  }
}

class _Pending extends ConsumerWidget {
  const _Pending({required this.status});
  final Json status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.syncPairTitle,
      subtitle: l.syncPairHelp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: l.syncPairCode,
          child: SelectableText(status.string('device_code'),
              style: context.text.displaySmall?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: Space.md),
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: Text(l.syncPairCheck),
          onPressed: () => _act(context, ref, ref.read(syncRepositoryProvider).run),
        ),
      ]),
    );
  }
}

class _Devices extends ConsumerWidget {
  const _Devices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final devices = ref.watch(syncDevicesProvider).valueOrNull ?? const <Json>[];
    return SectionCard(
      title: l.syncDevices,
      subtitle: l.syncDevicesHelp,
      child: Column(children: [
        for (final d in devices)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(d.string('platform') == 'linux' ? Icons.computer : Icons.desktop_windows_outlined),
            title: Text(d.flag('current') ? l.syncThisDevice(d.string('name')) : d.string('name')),
            subtitle: Text([
              switch (d.string('status')) {
                'pending' => l.syncDevicePending,
                'revoked' => l.syncDeviceRevoked,
                _ => l.syncDeviceActive,
              },
              if (d.str('last_seen_at') != null) Fmt.dateTime(context, d.str('last_seen_at')),
            ].join(' · ')),
            trailing: Wrap(spacing: Space.xs, children: [
              if (d.string('status') == 'pending')
                FilledButton(onPressed: () => _approve(context, ref, d), child: Text(l.syncApprove)),
              if (!d.flag('current') && d.string('status') != 'revoked')
                IconButton(
                  tooltip: l.syncRevoke,
                  icon: const Icon(Icons.block),
                  onPressed: () async {
                    final ok = await confirmAction(context, title: l.syncRevoke, message: d.string('name'),
                        confirmLabel: l.syncRevoke, destructive: true);
                    if (ok && context.mounted) await _act(context, ref, () => repo.revoke(d.string('id')));
                  },
                ),
            ]),
          ),
      ]),
    );
  }

  /// D-30: the user types the code shown on the new device; it must match the key about to be trusted.
  Future<void> _approve(BuildContext context, WidgetRef ref, Json device) async {
    final l = AppLocalizations.of(context);
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.syncApproveTitle(device.string('name'))),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.syncApproveHelp),
            const SizedBox(height: Space.md),
            TextField(
              controller: c,
              autofocus: true,
              decoration: InputDecoration(labelText: l.syncPairCode, hintText: '0000 0000 0000'),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.syncApprove)),
        ],
      ),
    );
    c.dispose();
    if (code == null || !context.mounted) return;
    await _act(context, ref, () => ref.read(syncRepositoryProvider).approve(device.string('id'), code), l.syncApproved);
  }
}

class _Conflicts extends ConsumerWidget {
  const _Conflicts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final conflicts = ref.watch(syncConflictsProvider).valueOrNull ?? const <Json>[];
    return SectionCard(
      title: l.syncConflicts,
      subtitle: l.syncConflictsHelp,
      child: Column(children: [
        for (final c in conflicts)
          Card(
            margin: const EdgeInsets.only(bottom: Space.md),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.syncConflictOn(c.string('kind'), c.obj('local').str('field') ?? '*'), style: context.text.titleSmall),
                const SizedBox(height: Space.sm),
                if (c.obj('local').str('reason') != null)
                  Text(l.syncSkipped(c.obj('local').string('reason')))
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _Version(title: l.syncThisVersion, text: '${c.obj('local')['value'] ?? ''}')),
                    const SizedBox(width: Space.md),
                    Expanded(child: _Version(title: l.syncOtherVersion, text: '${c.obj('remote')['value'] ?? ''}')),
                  ]),
                const SizedBox(height: Space.sm),
                Wrap(alignment: WrapAlignment.end, spacing: Space.sm, children: [
                  OutlinedButton(
                    onPressed: () => _act(context, ref, () => repo.resolve(c.integer('id')!, 'local')),
                    child: Text(l.syncKeepMine),
                  ),
                  if (c.obj('local').str('reason') == null)
                    FilledButton(
                      onPressed: () => _act(context, ref, () => repo.resolve(c.integer('id')!, 'remote')),
                      child: Text(l.syncTakeOther),
                    ),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Version extends StatelessWidget {
  const _Version({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(color: context.colors.surfaceContainerLow, borderRadius: Radii.control),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: context.text.labelMedium),
          const SizedBox(height: Space.xs),
          SelectableText(text),
        ]),
      );
}

class _Security extends ConsumerWidget {
  const _Security();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final account = ref.watch(_accountProvider).valueOrNull;
    final totp = account?.flag('totp_enabled') ?? false;
    return SectionCard(
      title: l.syncSecurity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (account != null)
          Text(l.syncQuota(Fmt.bytes(account.integer('bytes_used') ?? 0), Fmt.bytes(account.integer('quota_bytes') ?? 0))),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.syncTotp),
          subtitle: Text(l.syncTotpHelp),
          value: totp,
          onChanged: (v) => v ? _enableTotp(context, ref) : _disableTotp(context, ref),
        ),
        const Divider(),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l.syncDeleteRemote),
          onPressed: () async {
            final password = await _askPassword(context, l.syncDeleteRemote, l.syncDeleteRemoteHelp);
            if (password != null && context.mounted) {
              await _act(context, ref, () => repo.deleteRemote(password), l.syncDeletedRemote);
            }
          },
        ),
      ]),
    );
  }

  Future<void> _enableTotp(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    try {
      final setup = await repo.totpSetup();
      if (!context.mounted) return;
      final c = TextEditingController();
      final code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.syncTotp),
          content: SizedBox(
            width: 480,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.syncTotpSetup),
              const SizedBox(height: Space.md),
              SelectableText(setup.string('secret'), style: context.text.titleMedium?.copyWith(letterSpacing: 1.5)),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l.syncCopyUri),
                onPressed: () => Clipboard.setData(ClipboardData(text: setup.string('uri'))),
              ),
              TextField(controller: c, decoration: InputDecoration(labelText: l.syncTotpCode), keyboardType: TextInputType.number),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.syncTotpEnable)),
          ],
        ),
      );
      c.dispose();
      if (code == null || !context.mounted) return;
      await _act(context, ref, () => repo.totp('enable', code), l.syncTotpOn);
      ref.invalidate(_accountProvider);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _disableTotp(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final code = await _askPassword(context, l.syncTotp, l.syncTotpCode, numeric: true);
    if (code == null || !context.mounted) return;
    await _act(context, ref, () => ref.read(syncRepositoryProvider).totp('disable', code));
    ref.invalidate(_accountProvider);
  }

  Future<String?> _askPassword(BuildContext context, String title, String label, {bool numeric = false}) async {
    final l = AppLocalizations.of(context);
    final c = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: numeric
              ? TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label),
                  const SizedBox(height: Space.md),
                  PasswordField(controller: c, label: l.syncOnlinePassword),
                ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.commonContinue)),
        ],
      ),
    );
    c.dispose();
    return value;
  }
}

final _accountProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(syncRepositoryProvider).account());
