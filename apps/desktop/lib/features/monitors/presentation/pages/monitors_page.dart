import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/monitor_models.dart';
import '../data/monitor_repository.dart';

final monitorsProvider = FutureProvider<List<MonitorModel>>((ref) async {
  final repo = ref.watch(monitorRepositoryProvider);
  return repo.getMonitors();
});

class MonitorsPage extends ConsumerWidget {
  const MonitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorsAsync = ref.watch(monitorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes veilles',
          style: TextStyle(color: Color(0xFF0D1B3E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMonitorBottomSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle veille'),
        backgroundColor: const Color(0xFF22C55E),
      ),
      body: monitorsAsync.when(
        data: (monitors) {
          if (monitors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune veille configurée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez une veille pour être alerté des nouvelles opportunités.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showMonitorBottomSheet(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B3E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Créer ma première veille'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: monitors.length,
            itemBuilder: (context, index) {
              final monitor = monitors[index];
              return _MonitorCard(monitor: monitor);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  void _showMonitorBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    MonitorModel? monitor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonitorFormSheet(monitor: monitor),
    );
  }
}

class _MonitorCard extends ConsumerWidget {
  final MonitorModel monitor;

  const _MonitorCard({required this.monitor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    monitor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                ),
                Switch(
                  value: monitor.isActive,
                  onChanged: (val) {
                    // Toggle monitor
                    final repo = ref.read(monitorRepositoryProvider);
                    repo
                        .updateMonitor(
                          monitor.id,
                          monitor.copyWith(isActive: val),
                        )
                        .then((_) {
                          ref.invalidate(monitorsProvider);
                        });
                  },
                  activeColor: const Color(0xFF22C55E),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    monitor.frequency == MonitorFrequency.daily
                        ? 'Quotidienne'
                        : 'Hebdomadaire',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFE0F2FE),
                ),
                const Spacer(),
                if (monitor.minScore > 0)
                  Text(
                    'Score min: ${monitor.minScore}',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière exécution:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      monitor.lastRunAt != null
                          ? DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(monitor.lastRunAt!)
                          : 'Jamais',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochaine:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      monitor.nextRunAt != null
                          ? DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(monitor.nextRunAt!)
                          : '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Edit
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D1B3E),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Delete
                    final repo = ref.read(monitorRepositoryProvider);
                    repo
                        .deleteMonitor(monitor.id)
                        .then((_) => ref.invalidate(monitorsProvider));
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Run now
                    final repo = ref.read(monitorRepositoryProvider);
                    repo.runMonitorNow(monitor.id).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veille lancée')),
                      );
                      ref.invalidate(monitorsProvider);
                    });
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Lancer maintenant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitorFormSheet extends StatefulWidget {
  final MonitorModel? monitor;

  const _MonitorFormSheet({this.monitor});

  @override
  State<_MonitorFormSheet> createState() => _MonitorFormSheetState();
}

class _MonitorFormSheetState extends State<_MonitorFormSheet> {
  late TextEditingController _nameController;
  MonitorFrequency _frequency = MonitorFrequency.daily;
  double _minScore = 50;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.monitor?.name ?? '');
    if (widget.monitor != null) {
      _frequency = widget.monitor!.frequency;
      _minScore = widget.monitor!.minScore.toDouble();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.monitor == null ? 'Nouvelle veille' : 'Modifier la veille',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la veille',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MonitorFrequency>(
            value: _frequency,
            decoration: const InputDecoration(
              labelText: 'Fréquence',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: MonitorFrequency.daily,
                child: Text('Quotidienne'),
              ),
              DropdownMenuItem(
                value: MonitorFrequency.weekly,
                child: Text('Hebdomadaire'),
              ),
              DropdownMenuItem(
                value: MonitorFrequency.custom,
                child: Text('Personnalisée'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _frequency = val);
            },
          ),
          const SizedBox(height: 16),
          Text('Score minimum: ${_minScore.toInt()}'),
          Slider(
            value: _minScore,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _minScore = val),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Save
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B3E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
