import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/prefs/ui_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import 'command_palette.dart';
import 'nav_items.dart';

/// Desktop shell: collapsible sidebar + content. Keyboard shortcuts (EF-18.13): Ctrl+K command
/// palette, Ctrl+F search, Ctrl+1..9 sections, Ctrl+L lock, F1 or Ctrl+/ shortcut list.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(uiPrefsProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is SignedIn ? auth.user : null;
    final items = navItems(l);
    final narrow = MediaQuery.sizeOf(context).width < Layout.compactBreakpoint;
    final collapsed = prefs.sidebarCollapsed || narrow;
    final selected = items.indexWhere((i) => location.startsWith(i.path));

    void palette() => showCommandPalette(context, [
          for (final (i, item) in items.indexed)
            PaletteCommand(l.paletteGoTo(item.label), item.icon, () => context.go(item.path),
                shortcut: i < 9 ? 'Ctrl+${i + 1}' : null),
          PaletteCommand(l.dashNewSearch, Icons.travel_explore, () => context.go('/search'), shortcut: 'Ctrl+F'),
          PaletteCommand(l.monCreate, Icons.add_alert_outlined, () => context.go('/monitors')),
          PaletteCommand(l.srcAdd, Icons.add_link, () => context.go('/sources')),
          PaletteCommand(l.cvImport, Icons.upload_file, () => context.go('/profile/cv')),
          PaletteCommand(l.wsCreate, Icons.create_new_folder_outlined, () => context.go('/workspaces')),
          PaletteCommand(l.paletteTheme, Icons.contrast, () {
            final next = switch (prefs.themeMode) {
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
              ThemeMode.system => ThemeMode.light,
            };
            ref.read(uiPrefsProvider.notifier).setTheme(next);
          }, keywords: 'theme sombre dark clair light'),
          PaletteCommand(l.settingsPrivacy, Icons.privacy_tip_outlined, () => context.go('/settings?tab=2')),
          PaletteCommand(l.settingsAi, Icons.auto_awesome, () => context.go('/settings?tab=3')),
          PaletteCommand(l.settingsBackups, Icons.backup_outlined, () => context.go('/settings?tab=4')),
          PaletteCommand(l.shortcutsTitle, Icons.keyboard_outlined, () => showShortcutsHelp(context), shortcut: 'F1'),
          PaletteCommand(l.authLock, Icons.lock_outline, () => ref.read(authControllerProvider.notifier).lock(),
              shortcut: 'Ctrl+L'),
        ]);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyL, control: true): () =>
          ref.read(authControllerProvider.notifier).lock(),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): palette,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => context.go('/search'),
      const SingleActivator(LogicalKeyboardKey.f1): () => showShortcutsHelp(context),
      const SingleActivator(LogicalKeyboardKey.slash, control: true): () => showShortcutsHelp(context),
      for (var i = 0; i < items.length && i < 9; i++)
        SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i), control: true): () =>
            context.go(items[i].path),
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              AnimatedContainer(
                duration: Motion.of(context, Motion.normal),
                curve: Motion.standard,
                width: collapsed ? Layout.sidebarCollapsed : Layout.sidebarWidth,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(right: BorderSide(color: context.colors.outlineVariant)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Row(
                        children: [
                          const AppLogo(size: 36),
                          if (!collapsed) ...[
                            const SizedBox(width: Space.md),
                            Expanded(child: Text(l.appName, style: context.text.titleMedium, overflow: TextOverflow.ellipsis)),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _NavTile(item: items[i], selected: i == selected, collapsed: collapsed),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (user != null) _ProfileTile(user: user, collapsed: collapsed),
                    if (!narrow)
                      IconButton(
                        tooltip: collapsed ? l.navExpand : l.navCollapse,
                        onPressed: () => ref.read(uiPrefsProvider.notifier).toggleSidebar(),
                        icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
                      ),
                    const SizedBox(height: Space.sm),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.collapsed});

  final NavItem item;
  final bool selected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant;
    final tile = Material(
      color: selected ? context.colors.primaryContainer : Colors.transparent,
      borderRadius: Radii.control,
      child: InkWell(
        borderRadius: Radii.control,
        onTap: () => context.go(item.path),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : Space.md, vertical: Space.md),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, color: fg, size: 22),
              if (!collapsed) ...[
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(item.label,
                      style: context.text.labelLarge?.copyWith(color: fg), overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: collapsed ? Tooltip(message: item.label, child: tile) : tile,
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.user, required this.collapsed});

  final AppUser user;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.read(authControllerProvider.notifier);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: context.colors.primaryContainer,
      child: Text(user.displayName.characters.first.toUpperCase(),
          style: TextStyle(color: context.colors.onPrimaryContainer, fontSize: 14)),
    );
    return PopupMenuButton<String>(
      tooltip: user.displayName,
      onSelected: (v) => switch (v) {
        'lock' => auth.lock(),
        'logout' => auth.logout(),
        'shortcuts' => showShortcutsHelp(context),
        _ => context.go('/settings'),
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'settings', child: ListTile(leading: const Icon(Icons.settings_outlined), title: Text(l.navSettings))),
        PopupMenuItem(value: 'lock', child: ListTile(leading: const Icon(Icons.lock_outline), title: Text(l.authLock), subtitle: const Text('Ctrl+L'))),
        PopupMenuItem(value: 'shortcuts', child: ListTile(leading: const Icon(Icons.keyboard_outlined), title: Text(l.shortcutsTitle), subtitle: const Text('F1'))),
        PopupMenuItem(value: 'logout', child: ListTile(leading: const Icon(Icons.logout), title: Text(l.authSignOut))),
      ],
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            avatar,
            if (!collapsed) ...[
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: context.text.labelLarge, overflow: TextOverflow.ellipsis),
                    Text(user.isSynced ? l.authModeSynced : l.authModeLocal,
                        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
