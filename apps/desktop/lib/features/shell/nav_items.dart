import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Sidebar destinations. Only sections backed by working engine features are listed.
List<NavItem> navItems(AppLocalizations l) => [
      NavItem('/dashboard', l.navDashboard, Icons.space_dashboard_outlined, Icons.space_dashboard),
      NavItem('/search', l.navSearch, Icons.travel_explore_outlined, Icons.travel_explore),
      NavItem('/saved', l.navSaved, Icons.bookmarks_outlined, Icons.bookmarks),
      NavItem('/monitors', l.navMonitors, Icons.notifications_active_outlined, Icons.notifications_active),
      NavItem('/workspaces', l.navWorkspaces, Icons.folder_copy_outlined, Icons.folder_copy),
      NavItem('/sources', l.navSources, Icons.hub_outlined, Icons.hub),
      NavItem('/profile', l.navProfile, Icons.person_outline, Icons.person),
      NavItem('/settings', l.navSettings, Icons.settings_outlined, Icons.settings),
    ];

/// Where a freshly signed-in user lands.
const homePath = '/dashboard';
