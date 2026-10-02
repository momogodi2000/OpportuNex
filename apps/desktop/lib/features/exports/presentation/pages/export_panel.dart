import 'package:flutter/material.dart';

class ExportPanel extends StatefulWidget {
  const ExportPanel({super.key});

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  bool _exportSaved = true;
  bool _exportApps = false;
  bool _exportHistory = false;
  String _format = 'CSV';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exporter des données',
          style: TextStyle(color: Color(0xFF0D1B3E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez les données à exporter:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              title: const Text('Opportunités sauvegardées'),
              value: _exportSaved,
              onChanged: (v) => setState(() => _exportSaved = v ?? false),
              activeColor: const Color(0xFF22C55E),
            ),
            CheckboxListTile(
              title: const Text('Candidatures'),
              value: _exportApps,
              onChanged: (v) => setState(() => _exportApps = v ?? false),
              activeColor: const Color(0xFF22C55E),
            ),
            CheckboxListTile(
              title: const Text('Historique de recherche'),
              value: _exportHistory,
              onChanged: (v) => setState(() => _exportHistory = v ?? false),
              activeColor: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 24),
            const Text(
              'Format de fichier:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'CSV', child: Text('CSV (Tableur)')),
                DropdownMenuItem(value: 'XLSX', child: Text('Excel (XLSX)')),
                DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                DropdownMenuItem(
                  value: 'JSON',
                  child: Text('JSON (Développeur)'),
                ),
                DropdownMenuItem(
                  value: 'iCalendar',
                  child: Text('iCalendar (Événements/Deadlines)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _format = v);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.date_range),
                    label: const Text('Période: Toutes'),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _performExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isExporting ? 'Exportation en cours...' : 'Exporter',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performExport() async {
    setState(() => _isExporting = true);
    // Simulate export
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isExporting = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export terminé'),
          content: Text('Vos données ont été exportées au format $_format.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Save file dialog action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B3E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer sous...'),
            ),
          ],
        ),
      );
    }
  }
}
