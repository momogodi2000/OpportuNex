import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/opportunity_provider.dart';
import '../domain/opportunity_models.dart';
import 'widgets/match_score_panel.dart';

class OpportunityDetailPage extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailPage({Key? key, required this.opportunityId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(opportunityDetailProvider(opportunityId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: detailAsync.when(
          data: (detail) => Text(detail.title, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
        ),
        actions:
            detailAsync
                .whenData(
                  (detail) => [
                    IconButton(
                      icon: Icon(
                        detail.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      color: detail.isSaved ? const Color(0xFFF97316) : null,
                      onPressed: () {
                        ref.read(saveOpportunityProvider)(
                          detail.id,
                          !detail.isSaved,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              detail.isSaved
                                  ? 'Opportunité retirée des favoris'
                                  : 'Opportunité sauvegardée',
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                  ],
                )
                .valueOrNull ??
            [],
      ),
      body: detailAsync.when(
        data: (detail) {
          final isLargeScreen = MediaQuery.of(context).size.width > 1200;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(detail),
                      const SizedBox(height: 24),
                      _buildSummary(detail),
                      const SizedBox(height: 24),
                      _buildEligibility(detail),
                      const SizedBox(height: 24),
                      _buildRadarChart(),
                      const SizedBox(height: 24),
                      _buildAmount(detail),
                      const SizedBox(height: 24),
                      _buildDeadline(detail),
                      const SizedBox(height: 24),
                      _buildLocation(detail),
                      const SizedBox(height: 24),
                      _buildOriginalText(detail),
                      const SizedBox(height: 24),
                      _buildDetailedFields(detail),
                      const SizedBox(height: 24),
                      _buildSimilarOpportunities(detail),
                      const SizedBox(height: 24),
                      _buildActions(context, detail),
                    ],
                  ),
                ),
              ),
              if (isLargeScreen)
                Expanded(
                  flex: 3,
                  child: MatchScorePanel(score: detail.matchScore ?? 0),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildHeader(OpportunityDetail detail) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail.organization,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(detail.categoryId),
                    backgroundColor: const Color(0xFFE0E7FF),
                  ),
                ],
              ),
            ),
            if (detail.matchScore != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: detail.matchScore! > 70
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF97316),
                ),
                child: Center(
                  child: Text(
                    '${detail.matchScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(OpportunityDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Résumé IA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Généré',
                style: TextStyle(fontSize: 12, color: Colors.purple),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(detail.summaryAi),
      ],
    );
  }

  Widget _buildEligibility(OpportunityDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Éligibilité',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(detail.eligibilityAnalysis ?? 'Aucune analyse disponible.'),
      ],
    );
  }

  Widget _buildAmount(OpportunityDetail detail) {
    return Text(
      'Montant: ${detail.amountMin ?? ''} - ${detail.amountMax ?? ''} ${detail.currencyCode ?? 'FCFA'}',
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildDeadline(OpportunityDetail detail) {
    final daysLeft = detail.deadlineIso.difference(DateTime.now()).inDays;
    return Text(
      'Date limite: ${detail.deadlineIso.toLocal().toString().split(' ')[0]} ($daysLeft jours restants)',
      style: TextStyle(
        fontSize: 16,
        color: daysLeft < 7 ? Colors.red : Colors.black,
      ),
    );
  }

  Widget _buildLocation(OpportunityDetail detail) {
    return Text(
      'Localisation: ${detail.location} (${detail.countryCode})',
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildOriginalText(OpportunityDetail detail) {
    return ExpansionTile(
      title: const Text(
        'Texte original',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Text(detail.fullText),
        ),
      ],
    );
  }

  Widget _buildDetailedFields(OpportunityDetail detail) {
    return ExpansionTile(
      title: const Text(
        'Champs détaillés',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: detail.allFields
          .map(
            (f) => ListTile(
              title: Text(f.displayName),
              subtitle: Text(f.value),
              trailing: Text(f.provenance.toString().split('.').last),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSimilarOpportunities(OpportunityDetail detail) {
    if (detail.relatedOpportunities.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opportunités similaires',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: detail.relatedOpportunities.length,
            itemBuilder: (context, index) {
              final item = detail.relatedOpportunities[index];
              return Card(
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        item.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChart() {
    return SizedBox(
      height: 200,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          dataSets: [
            RadarDataSet(
              fillColor: const Color(0xFF22C55E).withOpacity(0.2),
              borderColor: const Color(0xFF22C55E),
              entryRadius: 2,
              dataEntries: [
                const RadarEntry(value: 80),
                const RadarEntry(value: 60),
                const RadarEntry(value: 90),
                const RadarEntry(value: 70),
                const RadarEntry(value: 85),
                const RadarEntry(value: 65),
                const RadarEntry(value: 95),
              ],
            ),
          ],
          getTitle: (index, angle) {
            return const RadarChartTitle(text: 'Critère'); // Placeholder
          },
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, OpportunityDetail detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Postuler'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D1B3E),
          ),
        ),
        OutlinedButton(onPressed: () {}, child: const Text('Exporter')),
        TextButton(
          onPressed: () {},
          child: const Text('Signaler', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
