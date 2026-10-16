import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/api/api_client.dart';
import 'package:opportunex/core/api/api_exception.dart';
import 'package:opportunex/features/ai/ai_consent.dart';
import 'package:opportunex/features/ai/ai_repository.dart';
import 'package:opportunex/l10n/app_localizations.dart';

class FakeAiRepository extends AiRepository {
  FakeAiRepository() : super(ApiClient(baseUrl: 'http://127.0.0.1:1', engineToken: 't'));
  final grants = <String, List<String>>{};

  @override
  Future<Json> grant(String id, List<String> purposes) async {
    grants[id] = purposes;
    return {'id': id};
  }

  @override
  Future<List<Json>> providers() async => const [];
}

/// Engine answer when consent is missing (RFC 9457 problem with extras).
ApiException _consentProblem() => ApiException.fromProblem(409, {
      'code': 'ai_consent_required',
      'provider_id': 'p1',
      'provider_name': 'Mistral',
      'purposes': ['ai_remote_processing', 'profile_to_ai'],
    });

Future<(FakeAiRepository, List<String>)> _pump(WidgetTester tester) async {
  final repo = FakeAiRepository();
  final results = <String>[];
  var calls = 0;
  await tester.pumpWidget(ProviderScope(
    overrides: [aiRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final r = await withAiConsent<String>(context, ref, () async {
                calls++;
                if (calls == 1) throw _consentProblem();
                return 'ai';
              }, withoutAi: () async => 'rules');
              results.add(r ?? 'null');
            },
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
  return (repo, results);
}

void main() {
  testWidgets('consent dialog names the provider and the data, then retries after "Allow"', (tester) async {
    final (repo, results) = await _pump(tester);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer des données à Mistral ?'), findsOneWidget);
    expect(find.textContaining('profil anonymisé'), findsOneWidget);
    expect(find.textContaining('jamais envoyés'), findsOneWidget);
    await tester.tap(find.text('Autoriser'));
    await tester.pumpAndSettle();
    expect(repo.grants, {'p1': ['ai_remote_processing', 'profile_to_ai']});
    expect(results, ['ai']);
  });

  testWidgets('"Continue without AI" records nothing and uses the rules', (tester) async {
    final (repo, results) = await _pump(tester);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer sans IA'));
    await tester.pumpAndSettle();
    expect(repo.grants, isEmpty);
    expect(results, ['rules']);
  });
}
