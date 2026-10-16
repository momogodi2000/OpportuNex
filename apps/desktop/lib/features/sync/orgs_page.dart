import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'sync_repository.dart';

String orgRoleLabel(AppLocalizations l, String role) => switch (role) {
      'owner' => l.roleOwner,
      'admin' => l.roleAdmin,
      'editor' => l.roleEditor,
      _ => l.roleViewer,
    };

/// Organisations (M17): shared workspaces and saved opportunities, encrypted with a group key.
class OrgsPage extends ConsumerWidget {
  const OrgsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider).valueOrNull;
    final ready = status != null && status.flag('linked') && status.flag('paired');
    return PageFrame(
      title: l.navOrgs,
      subtitle: l.orgsSubtitle,
      actions: [
        if (ready) ...[
          OutlinedButton.icon(onPressed: () => _join(context, ref), icon: const Icon(Icons.login), label: Text(l.orgsJoin)),
          FilledButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.group_add_outlined), label: Text(l.orgsCreate)),
        ],
      ],
      child: !ready
          ? EmptyState(
              icon: Icons.sync_disabled,
              title: l.orgsNeedSync,
              message: l.orgsNeedSyncBody,
              action: FilledButton(onPressed: () => context.go('/settings?tab=4'), child: Text(l.orgsOpenSync)),
            )
          : AsyncView<List<Json>>(
              value: ref.watch(orgsProvider),
              onRetry: () => ref.invalidate(orgsProvider),
              isEmpty: (list) => list.isEmpty,
              empty: EmptyState(icon: Icons.groups_outlined, title: l.orgsEmpty, message: l.orgsEmptyBody),
              data: (orgs) => Column(children: [
                for (final o in orgs)
                  Card(
                    margin: const EdgeInsets.only(bottom: Space.md),
                    child: ListTile(
                      leading: const Icon(Icons.groups_outlined),
                      title: Text(o.string('name')),
                      subtitle: Text('${orgRoleLabel(l, o.string('role'))} · ${l.orgsKeyVersion(o.integer('key_version') ?? 1)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/orgs/${o.string('id')}'),
                    ),
                  ),
              ]),
            ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final name = TextEditingController();
    var type = 'association';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.orgsCreate),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l.orgName)),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: l.orgType),
                items: [
                  for (final (code, label) in [('association', l.orgAssociation), ('ngo', l.orgNgo), ('sme', l.orgSme),
                    ('startup', l.orgStartup), ('cooperative', l.orgCooperative), ('public', l.orgPublic),
                    ('academic', l.orgAcademic), ('other', l.psOther)])
                    DropdownMenuItem(value: code, child: Text(label)),
                ],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.orgsCreate)),
          ],
        ),
      ),
    );
    final value = name.text.trim();
    name.dispose();
    if (ok != true || value.isEmpty) return;
    try {
      await ref.read(syncRepositoryProvider).createOrg({'name': value, 'org_type': type});
      ref.invalidate(orgsProvider);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final c = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.orgsJoin),
        content: SizedBox(
          width: 460,
          child: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: l.orgsInviteCode)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.orgsJoin)),
        ],
      ),
    );
    c.dispose();
    if (token == null || token.isEmpty) return;
    try {
      await ref.read(syncRepositoryProvider).join(token);
      await ref.read(syncRepositoryProvider).run();
      ref.invalidate(orgsProvider);
      if (context.mounted) showSuccess(context, l.orgsJoined);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

final _membersProvider =
    FutureProvider.autoDispose.family<Json, String>((ref, id) => ref.watch(syncRepositoryProvider).members(id));
final _auditProvider =
    FutureProvider.autoDispose.family<List<Json>, String>((ref, id) => ref.watch(syncRepositoryProvider).audit(id));

class OrgPage extends ConsumerWidget {
  const OrgPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(syncRepositoryProvider);
    final org = (ref.watch(orgsProvider).valueOrNull ?? const <Json>[]).where((o) => o.string('id') == id).firstOrNull;
    final role = org?.string('role') ?? 'viewer';
    final manager = role == 'owner' || role == 'admin';
    Future<void> act(Future<Object?> Function() fn, [String? done]) async {
      try {
        await fn();
        ref
          ..invalidate(_membersProvider(id))
          ..invalidate(_auditProvider(id))
          ..invalidate(orgsProvider);
        if (done != null && context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return PageFrame(
      title: org?.string('name') ?? l.navOrgs,
      subtitle: org == null ? null : orgRoleLabel(l, role),
      actions: [
        if (manager)
          FilledButton.icon(onPressed: () => _invite(context, ref), icon: const Icon(Icons.person_add_alt), label: Text(l.orgsInvite)),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l.orgsLeave),
          onPressed: () async {
            final ok = await confirmAction(context, title: l.orgsLeave, message: l.orgsLeaveConfirm, confirmLabel: l.orgsLeave);
            if (!ok) return;
            await act(() => repo.leave(id), l.orgsLeft);
            if (context.mounted) context.go('/orgs');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionCard(
          title: l.orgsMembers,
          subtitle: l.orgsMembersHelp,
          child: AsyncView<Json>(
            value: ref.watch(_membersProvider(id)),
            onRetry: () => ref.invalidate(_membersProvider(id)),
            data: (m) => Column(children: [
              for (final member in m.list('items'))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(member.flag('has_current_key') ? Icons.vpn_key_outlined : Icons.hourglass_empty),
                  title: Text(member.string('email')),
                  subtitle: Text([
                    l.orgsJoinedOn(Fmt.date(context, member.str('joined_at'))),
                    if (member.str('key_fingerprint') != null) l.orgsFingerprint(member.string('key_fingerprint')),
                    if (!member.flag('has_current_key')) l.orgsKeyPending,
                  ].join(' · ')),
                  trailing: manager
                      ? Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.xs, children: [
                          DropdownButton<String>(
                            value: member.string('role'),
                            items: [
                              for (final r in const ['owner', 'admin', 'editor', 'viewer'])
                                DropdownMenuItem(value: r, child: Text(orgRoleLabel(l, r))),
                            ],
                            onChanged: (r) => r == null
                                ? null
                                : act(() => repo.setRole(id, member.string('account_id'), r)),
                          ),
                          IconButton(
                            tooltip: l.orgsRemove,
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () async {
                              final ok = await confirmAction(context, title: l.orgsRemove, message: member.string('email'),
                                  confirmLabel: l.orgsRemove, destructive: true);
                              if (ok) await act(() => repo.removeMember(id, member.string('account_id')));
                            },
                          ),
                        ])
                      : Text(orgRoleLabel(l, member.string('role'))),
                ),
            ]),
          ),
        ),
        if (manager) ...[
          const SizedBox(height: Space.xl),
          SectionCard(
            title: l.orgsAudit,
            child: AsyncView<List<Json>>(
              value: ref.watch(_auditProvider(id)),
              onRetry: () => ref.invalidate(_auditProvider(id)),
              data: (events) => Column(children: [
                for (final e in events.take(50))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_auditLabel(l, e.string('action'))),
                    subtitle: Text([e.str('email'), Fmt.dateTime(context, e.str('created_at'))].whereType<String>().join(' · ')),
                  ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  String _auditLabel(AppLocalizations l, String action) => switch (action) {
        'org.create' => l.auditCreate,
        'invite.create' => l.auditInvite,
        'invite.revoke' => l.auditInviteRevoke,
        'member.join' => l.auditJoin,
        'member.leave' => l.auditLeave,
        'member.remove' => l.auditRemove,
        'member.role' => l.auditRole,
        'key.rotate' => l.auditRotate,
        'key.share' => l.auditKeyShare,
        _ => action,
      };

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final email = TextEditingController();
    var role = 'editor';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.orgsInvite),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: email, decoration: InputDecoration(labelText: l.orgsInviteEmail, helperText: l.orgsInviteEmailHelp)),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(labelText: l.orgsRole),
                items: [
                  for (final r in const ['admin', 'editor', 'viewer']) DropdownMenuItem(value: r, child: Text(orgRoleLabel(l, r))),
                ],
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.orgsInvite)),
          ],
        ),
      ),
    );
    final mail = email.text.trim();
    email.dispose();
    if (ok != true) return;
    try {
      final inv = await ref.read(syncRepositoryProvider).invite(id, mail.isEmpty ? null : mail, role);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.orgsInviteReady),
          content: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mail.isEmpty ? l.orgsInviteShare : l.orgsInviteSent(mail)),
              const SizedBox(height: Space.md),
              SelectableText(inv.string('token'), style: ctx.text.titleSmall),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l.orgsCopyCode),
                onPressed: () => Clipboard.setData(ClipboardData(text: inv.string('token'))),
              ),
              Text(l.orgsInviteExpires(Fmt.dateTime(ctx, inv.str('expires_at'))), style: ctx.text.bodySmall),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonClose))],
        ),
      );
      ref.invalidate(_auditProvider(id));
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

/// "Share with an organisation" for a workspace or a saved opportunity (EF-17.03).
Future<void> shareWithOrg(BuildContext context, WidgetRef ref, String kind, String id, String? current) async {
  final l = AppLocalizations.of(context);
  final orgs = await ref.read(orgsProvider.future);
  if (!context.mounted) return;
  if (orgs.isEmpty) {
    showError(context, l.orgsNoneToShare);
    return;
  }
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(title: Text(l.orgsShareTitle), children: [
      for (final o in orgs)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, o.string('id')),
          child: ListTile(
            leading: Icon(current == o.string('id') ? Icons.check : Icons.groups_outlined),
            title: Text(o.string('name')),
            subtitle: Text(orgRoleLabel(l, o.string('role'))),
          ),
        ),
      if (current != null)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, ''),
          child: ListTile(leading: const Icon(Icons.person_outline), title: Text(l.orgsMakePersonal)),
        ),
    ]),
  );
  if (choice == null || !context.mounted) return;
  try {
    await ref.read(syncRepositoryProvider).share(kind, id, choice.isEmpty ? null : choice);
    if (context.mounted) showSuccess(context, choice.isEmpty ? l.orgsMadePersonal : l.orgsShared2);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}
