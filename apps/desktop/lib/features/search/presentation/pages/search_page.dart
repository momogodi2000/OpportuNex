import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../widgets/search_result_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildTopBar(state),
          if (state.status == SearchState.searching) _buildProgressBar(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildTopBar(SearchPageStateModel state) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) =>
                ref.read(searchProvider.notifier).interpretQuery(val),
            decoration: InputDecoration(
              hintText:
                  'Recherchez en langage naturel... ex: "bourses master droit francophone Cameroun"',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0D1B3E)),
              suffixIcon: IconButton(
                icon: Icon(_filtersExpanded ? Icons.tune : Icons.tune_outlined),
                onPressed: () {
                  setState(() => _filtersExpanded = !_filtersExpanded);
                },
                tooltip: 'Filtres',
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            style: const TextStyle(fontSize: 16),
          ),
          if (state.interpretation != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Interprété comme:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                ...state.interpretation!.interpretedFilters.categories.map(
                  (c) => _buildNlpChip(c, Icons.category),
                ),
                ...state.interpretation!.interpretedFilters.countries.map(
                  (c) => _buildNlpChip(c, Icons.flag),
                ),
              ],
            ),
          ],
          if (_filtersExpanded) _buildFiltersPanel(state),
        ],
      ),
    );
  }

  Widget _buildNlpChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 14, color: const Color(0xFF22C55E)),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFF22C55E).withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildFiltersPanel(SearchPageStateModel state) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(),
                  ),
                  value: state.filters.sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text('Pertinence'),
                    ),
                    DropdownMenuItem(
                      value: 'deadline',
                      child: Text('Date limite'),
                    ),
                    DropdownMenuItem(value: 'recent', child: Text('Récent')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(searchProvider.notifier)
                          .applyFilters(state.filters.copyWith(sortBy: val));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Télétravail uniquement'),
                  value: state.filters.remoteOnly,
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(searchProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(remoteOnly: val),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(searchProvider.notifier).applyFilters(state.filters);
              setState(() => _filtersExpanded = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1B3E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Appliquer les filtres'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(SearchPageStateModel state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 8),
          Text(
            state.currentSource ?? 'Recherche en cours...',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchPageStateModel state) {
    if (state.status == SearchState.idle && state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Lancez votre première recherche',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez la barre de recherche ci-dessus.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state.status == SearchState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(searchProvider.notifier).applyFilters(state.filters),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty && state.status == SearchState.results) {
      return const Center(child: Text('Aucun résultat trouvé.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          ref.read(searchProvider.notifier).loadMore();
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.results.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.results.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final result = state.results[index];
          return SearchResultCard(
            result: result,
            onSave: () {
              // TODO: implement save
            },
            onTap: () {
              // TODO: navigate to details
            },
          );
        },
      ),
    );
  }
}
