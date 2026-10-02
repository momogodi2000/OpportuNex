import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/saved')) return 2;
    if (location.startsWith('/applications')) return 3;
    if (location.startsWith('/monitors')) return 4;
    if (location.startsWith('/spaces')) return 5;
    if (location.startsWith('/sources')) return 6;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/saved');
        break;
      case 3:
        context.go('/applications');
        break;
      case 4:
        context.go('/monitors');
        break;
      case 5:
        context.go('/spaces');
        break;
      case 6:
        context.go('/sources');
        break;
    }
  }

  String _getBreadcrumb(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 'Tableau de bord';
    if (location.startsWith('/search')) return 'Recherche';
    if (location.startsWith('/saved')) return 'Sauvegardées';
    if (location.startsWith('/applications')) return 'Candidatures';
    if (location.startsWith('/monitors')) return 'Surveiller';
    if (location.startsWith('/spaces')) return 'Espaces';
    if (location.startsWith('/sources')) return 'Sources';
    return 'Accueil';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final selectedIndex = _calculateSelectedIndex(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          context.go('/search');
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
      },
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              _buildSidebar(isDesktop, selectedIndex, context),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    bool isDesktop,
    int selectedIndex,
    BuildContext context,
  ) {
    return Container(
      width: isDesktop ? 240 : 64,
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Center(
              child: isDesktop
                  ? RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: 'Opportu',
                            style: TextStyle(color: const Color(0xFF0D1B3E)),
                          ),
                          TextSpan(
                            text: 'Nex',
                            style: TextStyle(color: const Color(0xFF22C55E)),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      'ON',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  Icons.grid_view_rounded,
                  'Dashboard',
                  0,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.search_rounded,
                  'Recherche',
                  1,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.bookmark_rounded,
                  'Sauvegardées',
                  2,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.send_rounded,
                  'Candidatures',
                  3,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.notifications_rounded,
                  'Surveiller',
                  4,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.folder_rounded,
                  'Espaces',
                  5,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
                _buildNavItem(
                  Icons.storage_rounded,
                  'Sources',
                  6,
                  selectedIndex,
                  isDesktop,
                  context,
                ),
              ],
            ),
          ),
          const Divider(),
          _buildNavItem(
            Icons.business_rounded,
            'Organisations',
            -1,
            selectedIndex,
            isDesktop,
            context,
            isBottom: true,
          ),
          _buildNavItem(
            Icons.settings_rounded,
            'Paramètres',
            -2,
            selectedIndex,
            isDesktop,
            context,
            isBottom: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int selectedIndex,
    bool isDesktop,
    BuildContext context, {
    bool isBottom = false,
  }) {
    final isSelected = index == selectedIndex;
    final color = isSelected
        ? const Color(0xFF22C55E)
        : const Color(0xFF0D1B3E).withOpacity(0.6);

    return InkWell(
      onTap: () {
        if (!isBottom) {
          _onItemTapped(index, context);
        } else {
          if (index == -1) context.go('/organizations');
          if (index == -2) context.go('/settings');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22C55E).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: isDesktop
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Text(
            _getBreadcrumb(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Rechercher (Ctrl+K)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
          _buildEngineStatus(),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF0D1B3E),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'logout') {
                // handle logout
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profil')),
              const PopupMenuItem(value: 'lock', child: Text('Verrouiller')),
              const PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
            ],
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0D1B3E),
              child: Text(
                'JD',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineStatus() {
    return Tooltip(
      message: 'Moteur de scraping en ligne',
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'En ligne',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
