import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saved_provider.dart';

class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedOpportunitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Opportunités Sauvegardées',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: savedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text("Aucune opportunité sauvegardée"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildSavedCard(context, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("Erreur: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text('Toutes'),
              selected: true,
              onSelected: (_) {},
            ),
            SizedBox(width: 8),
            FilterChip(label: Text('Haute priorité'), onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text('Moyenne'), onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text('Basse'), onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text('Avec date limite'), onSelected: (_) {}),
            SizedBox(width: 16),
            Text('Trier par:'),
            SizedBox(width: 8),
            DropdownButton<String>(
              value: 'Date limite',
              items: [
                'Date limite',
                'Score',
                'Récemment sauvegardé',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCard(BuildContext context, dynamic item) {
    final title = item['opportunity_id'] ?? 'Opportunité inconnue'; // since we don't fetch full opp
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Haute priorité',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.bookmark, color: Color(0xFFF97316)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Retiré des favoris'),
                              action: SnackBarAction(
                                label: 'Annuler',
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Banque Africaine de Développement',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Expire dans 3 jours',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Score: 85%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text('Postuler'),
            ),
          ],
        ),
      ),
    );
  }
}
