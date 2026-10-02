import 'package:flutter/material.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Opportunités Sauvegardées',
          style: TextStyle(
            color: Color(0xFF0D1B3E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3, // Mock count
              itemBuilder: (context, index) {
                return _buildSavedCard(context);
              },
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
              label: const Text('Toutes'),
              selected: true,
              onSelected: (_) {},
            ),
            const SizedBox(width: 8),
            FilterChip(label: const Text('Haute priorité'), onSelected: (_) {}),
            const SizedBox(width: 8),
            FilterChip(label: const Text('Moyenne'), onSelected: (_) {}),
            const SizedBox(width: 8),
            FilterChip(label: const Text('Basse'), onSelected: (_) {}),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Avec date limite'),
              onSelected: (_) {},
            ),
            const SizedBox(width: 16),
            const Text('Trier par:'),
            const SizedBox(width: 8),
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

  Widget _buildSavedCard(BuildContext context) {
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
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Haute priorité',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark,
                          color: Color(0xFFF97316),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Retiré des favoris'),
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
                  const Text(
                    "Subvention pour projets agricoles en Afrique de l'Ouest",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Banque Africaine de Développement',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
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
                        child: const Text(
                          'Expire dans 3 jours',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
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
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B3E),
              ),
              child: const Text('Postuler'),
            ),
          ],
        ),
      ),
    );
  }
}
