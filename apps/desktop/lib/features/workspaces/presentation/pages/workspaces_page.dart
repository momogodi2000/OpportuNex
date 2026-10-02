import 'package:flutter/material.dart';

class WorkspacesPage extends StatelessWidget {
  const WorkspacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Espaces de travail',
          style: TextStyle(color: Color(0xFF0D1B3E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkspaceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Créer un espace'),
        backgroundColor: const Color(0xFF0D1B3E),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: 4, // Mock data
        itemBuilder: (context, index) {
          final titles = [
            "Recherche d'emploi",
            "Bourses d'études",
            "Appels d'offres",
            'Freelance 2026',
          ];
          return _WorkspaceCard(title: titles[index]);
        },
      ),
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel espace de travail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'emploi',
              decoration: const InputDecoration(
                labelText: 'Modèle',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'emploi',
                  child: Text("Recherche d'emploi"),
                ),
                DropdownMenuItem(value: 'bourses', child: Text('Bourses')),
                DropdownMenuItem(
                  value: 'offres',
                  child: Text("Appels d'offres"),
                ),
                DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
              ],
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String title;

  const _WorkspaceCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archiver'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Créé le 01/10/2026',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '12',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      Text(
                        'Recherches',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '45',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                      Text(
                        'Opportunités',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
