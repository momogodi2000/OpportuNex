import 'package:flutter/material.dart';

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Mes Candidatures',
            style: TextStyle(
              color: Color(0xFF0D1B3E),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Color(0xFF0D1B3E),
            indicatorColor: Color(0xFF22C55E),
            tabs: [
              Tab(text: 'Kanban', icon: Icon(Icons.view_kanban)),
              Tab(text: 'Liste', icon: Icon(Icons.list)),
              Tab(text: 'Calendrier', icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_KanbanTab(), _ListTab(), _CalendarTab()],
        ),
      ),
    );
  }
}

class _KanbanTab extends StatelessWidget {
  const _KanbanTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold basic implementation
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn('À revoir', Colors.grey),
          _buildColumn('En préparation', Colors.orange),
          _buildColumn('Soumis(es)', Colors.blue),
          _buildColumn('Résultat', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildColumn(String title, Color color) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            itemBuilder: (context, index) => _buildKanbanCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: const Text(
                    'Haute',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: Colors.red[400],
                  padding: EdgeInsets.zero,
                ),
                const Text(
                  'Mis à jour il y a 2j',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Bourse d'excellence Francophonie",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '30 Oct 2024',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list),
              label: const Text('Filtrer'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('Action groupée'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DataTable(
          columns: const [
            DataColumn(label: Text('Titre')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Priorité')),
            DataColumn(label: Text('Date limite')),
          ],
          rows: [
            DataRow(
              cells: [
                const DataCell(Text('Bourse Eiffel')),
                DataCell(
                  Chip(
                    label: const Text('En préparation'),
                    backgroundColor: Colors.orange[100],
                  ),
                ),
                const DataCell(Text('Haute')),
                const DataCell(Text('15 Nov 2024')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vue calendrier (En construction)',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
