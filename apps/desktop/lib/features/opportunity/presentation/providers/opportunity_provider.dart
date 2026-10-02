import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/opportunity_models.dart';
import '../data/opportunity_repository.dart';

class SearchFilters {
  final String? category;
  final String? country;
  final String? language;
  final String? source;
  final String? deadlineBefore;
  final String? deadlineAfter;
  final double? amountMin;
  final double? amountMax;
  final int? minScore;
  final bool? isSaved;
  final String? sortBy;
  final String? cursor;
  final int limit;

  const SearchFilters({
    this.category,
    this.country,
    this.language,
    this.source,
    this.deadlineBefore,
    this.deadlineAfter,
    this.amountMin,
    this.amountMax,
    this.minScore,
    this.isSaved,
    this.sortBy,
    this.cursor,
    this.limit = 20,
  });
}

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepository(
    client: http.Client(),
    baseUrl: 'https://api.opportunex.com', // Replace with config
  );
});

final opportunityListProvider =
    AsyncNotifierProvider.family<
      OpportunityListNotifier,
      List<OpportunityListItem>,
      SearchFilters
    >(() {
      return OpportunityListNotifier();
    });

class OpportunityListNotifier
    extends FamilyAsyncNotifier<List<OpportunityListItem>, SearchFilters> {
  @override
  Future<List<OpportunityListItem>> build(SearchFilters arg) async {
    final repo = ref.watch(opportunityRepositoryProvider);
    return await repo.getOpportunities(
      category: arg.category,
      country: arg.country,
      language: arg.language,
      source: arg.source,
      deadlineBefore: arg.deadlineBefore,
      deadlineAfter: arg.deadlineAfter,
      amountMin: arg.amountMin,
      amountMax: arg.amountMax,
      minScore: arg.minScore,
      isSaved: arg.isSaved,
      sortBy: arg.sortBy,
      cursor: arg.cursor,
      limit: arg.limit,
    );
  }
}

final opportunityDetailProvider =
    AsyncNotifierProvider.family<
      OpportunityDetailNotifier,
      OpportunityDetail,
      String
    >(() {
      return OpportunityDetailNotifier();
    });

class OpportunityDetailNotifier
    extends FamilyAsyncNotifier<OpportunityDetail, String> {
  @override
  Future<OpportunityDetail> build(String arg) async {
    final repo = ref.watch(opportunityRepositoryProvider);
    return await repo.getOpportunityById(arg);
  }
}

final saveOpportunityProvider = Provider((ref) {
  return (String id, bool save) async {
    final repo = ref.read(opportunityRepositoryProvider);
    await repo.updateOpportunity(id, {'isSaved': save});
    // Invalidate detail provider to refresh state
    ref.invalidate(opportunityDetailProvider(id));
  };
});
