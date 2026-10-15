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
      NavItem('/settings', l.navSettings, Icons.settings_outlined, Icons.settings),
    ];

/// Where a freshly signed-in user lands.
const homePath = '/settings';
