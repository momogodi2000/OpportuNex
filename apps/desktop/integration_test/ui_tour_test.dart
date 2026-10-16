import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opportunex/app.dart';
import 'package:opportunex/core/api/api_client.dart';
import 'package:opportunex/core/api/json.dart';
import 'package:opportunex/core/engine/engine_supervisor.dart';
import 'package:opportunex/core/prefs/ui_prefs.dart';
import 'package:opportunex/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI tour: the real app against the real engine and a local publisher, with realistic data.
///
/// Saves a PNG of every page (light, dark, minimum window size, English) under `build/ui_tour/`
/// and records every layout error (overflow, exceptions) per page in `build/ui_tour/report.txt`.
/// It is a review tool: it fails only if a page throws or overflows.
///
///     flutter test integration_test/ui_tour_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UI tour', (tester) async {
    final out = Directory('build/ui_tour')..createSync(recursive: true);
    for (final f in out.listSync()) {
      f.deleteSync();
    }
    final dataDir = Directory.systemTemp.createTempSync('opx-tour-');
    final site = await _Publisher.start();
    final sync = await _SyncServer.start(dataDir);
    final problems = <String>[];
    var current = 'start';
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (d) => problems.add('[$current] ${d.exceptionAsString().split('\n').first}');

    SharedPreferences.setMockInitialValues({'locale': 'fr', 'theme': 'light'});
    final container = ProviderContainer();
    container.read(engineSupervisorProvider.notifier).spawn = (c) => Process.start(c.executable, c.arguments,
        workingDirectory: c.workingDirectory,
        environment: {
          'OPX_DATA_DIR': dataDir.path,
          'OPX_KDF_MEMORY_KIB': '8192',
          'OPX_KDF_ITERATIONS': '1',
          'OPX_ALLOW_PRIVATE_NETWORK': 'true',
          'PYTHONUNBUFFERED': '1',
          'PYTHONIOENCODING': 'utf-8',
        });

    final key = GlobalKey();
    final a11y = <String>[];
    final semantics = tester.ensureSemantics();

    // Flutter's accessibility guidelines on the page currently shown (labels on every tap target,
    // measured text contrast); findings go to the report for review.
    Future<void> audit(String name) async {
      for (final (label, guideline) in [
        ('labels', labeledTapTargetGuideline),
        ('contrast', textContrastGuideline),
      ]) {
        try {
          final result = await guideline.evaluate(tester);
          if (!result.passed) {
            for (final line in result.reason!.split('\n').where((x) => x.trim().isNotEmpty).take(6)) {
              a11y.add('[$name] $label: $line');
            }
          }
        } on Object catch (e) {
          a11y.add('[$name] $label: could not evaluate ($e)');
        }
      }
    }
    Future<void> size(Size s) async {
      tester.view.physicalSize = s;
      tester.view.devicePixelRatio = 1.0;
      await tester.pump();
    }

    Future<void> settle([int frames = 12]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> waitFor(Finder f, {int seconds = 60}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
        if (f.evaluate().isNotEmpty) return;
      }
      fail('timed out waiting for $f on $current');
    }

    Future<void> shot(String name) async {
      current = name;
      await settle();
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    Future<void> go(String path, String name) async {
      current = name;
      // Leave the page first: tabbed pages read their initial tab only when created.
      container.read(routerProvider).go(path.startsWith('/sources') ? '/profile' : '/sources');
      await tester.pump(const Duration(milliseconds: 100));
      container.read(routerProvider).go(path);
      await shot(name);
    }

    await size(const Size(1440, 900));
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: UncontrolledProviderScope(container: container, child: const OpportunexApp()),
    ));

    // ---------------------------------------------------------------- first run
    current = 'welcome';
    await waitFor(find.text('Créer un profil'));
    await shot('01_welcome');
    await tester.tap(find.text('Créer un profil'));
    await settle();
    final fields = find.byType(TextFormField);
    const password = 'Baobab-Lumiere-Kribi-2026!';
    await tester.enterText(fields.at(0), 'Awa Ndjock');
    await tester.enterText(fields.at(1), 'awa@example.com');
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), password);
    await tester.tap(find.byType(CheckboxListTile));
    await shot('02_register');
    await tester.tap(find.text('Créer un compte'));
    await waitFor(find.text('Votre phrase de récupération'));
    await shot('03_recovery_phrase');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuer'));
    await waitFor(find.text('Configurer votre profil'));
    await shot('04_onboarding_empty');

    // ------------------------------------------------------------- realistic data
    final api = container.read(apiClientProvider)!;
    late final Map<String, String> ids;
    await tester.runAsync(() async => ids = await _seed(api, site, sync));

    await go('/onboarding', '05_onboarding_filled');
    await go('/dashboard', '06_dashboard');

    final pages = <(String, String)>[
      ('/dashboard', 'dashboard'),
      ('/search?run=${ids['run']}', 'search_results'),
      ('/opportunities/${ids['opp']}', 'opportunity'),
      ('/saved', 'saved_list'),
      ('/saved?tab=1', 'saved_board'),
      ('/saved?tab=2', 'saved_calendar'),
      ('/saved/${ids['saved']}', 'application'),
      ('/monitors', 'monitors'),
      ('/workspaces', 'workspaces'),
      ('/workspaces/${ids['workspace']}', 'workspace'),
      ('/sources', 'sources'),
      ('/orgs', 'orgs'),
      ('/orgs/${ids['org']}', 'org'),
      ('/profile', 'profile'),
      ('/profile/cv', 'cv_import'),
      ('/settings?tab=0', 'settings_account'),
      ('/settings?tab=1', 'settings_preferences'),
      ('/settings?tab=2', 'settings_privacy'),
      ('/settings?tab=3', 'settings_ai'),
      ('/settings?tab=4', 'settings_sync'),
      ('/settings?tab=5', 'settings_backups'),
      ('/settings?tab=6', 'settings_maintenance'),
      ('/settings?tab=7', 'settings_about'),
      ('/legal', 'legal'),
    ];
    await container.read(uiPrefsProvider.notifier).setTheme(ThemeMode.light);
    for (final (path, name) in pages) {
      await go(path, 'light_$name');
      await audit('light_$name');
    }

    await container.read(uiPrefsProvider.notifier).setTheme(ThemeMode.dark);
    for (final (path, name) in pages) {
      await go(path, 'dark_$name');
      await audit('dark_$name');
    }
    await container.read(uiPrefsProvider.notifier).setTheme(ThemeMode.light);

    await size(const Size(960, 640));
    for (final (path, name) in pages) {
      await go(path, 'small_$name');
    }

    // Large text (150 %): layout must not overflow.
    await size(const Size(1440, 900));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    for (final (path, name) in pages) {
      await go(path, 'large_$name');
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();

    await container.read(uiPrefsProvider.notifier).setLocale('en');
    for (final (path, name) in pages.take(8)) {
      await go(path, 'en_$name');
    }
    await container.read(uiPrefsProvider.notifier).setLocale('fr');

    // Lock screen last.
    current = 'lock';
    await tester.runAsync(() => api.postJson('/auth/lock'));
    await waitFor(find.text('Profil verrouillé'));
    await shot('99_locked');

    FlutterError.onError = previousOnError;
    semantics.dispose();
    File('${out.path}/report.txt').writeAsStringSync([
      '# Layout problems (overflow, exceptions)',
      if (problems.isEmpty) 'none' else ...problems,
      '',
      '# Accessibility guideline findings',
      if (a11y.isEmpty) 'none' else ...a11y,
      '',
    ].join('\n'));
    await container.read(engineSupervisorProvider.notifier).stop();
    container.dispose();
    await site.close();
    sync.stop();
    expect(problems, isEmpty, reason: problems.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 15)));
}

String _d(int days) => DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

/// Fills the profile and creates the data every page needs, through the real engine API.
Future<Map<String, String>> _seed(ApiClient api, _Publisher site, _SyncServer sync) async {
  await api.putJson('/profile/general', body: {
    'full_name': 'Awa Ndjock', 'country_code': 'CM', 'city': 'Douala', 'professional_status': 'employed',
    'current_occupation': 'Analyste de données', 'highest_education': 'master', 'experience_years': 4,
    'work_mode_pref': 'hybrid', 'willing_to_relocate': true,
    'bio': 'Analyste de données passionnée par la statistique appliquée au développement.',
  });
  await api.postJson('/profile/education', body: {
    'level': 'Master', 'field_of_study': 'Statistique et économie appliquée', 'institution': 'Université de Yaoundé II',
    'country_code': 'CM', 'start_date': '2017-09', 'end_date': '2019-07',
  });
  await api.postJson('/profile/experiences', body: {
    'job_title': 'Analyste de données', 'employer': 'Banque Atlantique', 'employment_type': 'full_time',
    'country_code': 'CM', 'city': 'Douala', 'start_date': '2021-02', 'is_current': true,
    'description': 'Tableaux de bord, modèles de risque, automatisation des rapports.',
  });
  await api.putJson('/profile/skills', body: [
    {'name': 'Python'}, {'name': 'SQL'}, {'name': 'Power BI'}, {'name': 'Statistiques'},
  ]);
  await api.putJson('/profile/languages', body: [
    {'language_code': 'fr', 'cefr_level': 'native'}, {'language_code': 'en', 'cefr_level': 'B2'},
  ]);
  await api.putJson('/profile/objectives', body: {'objective_ids': [1, 4]});

  final source = await api.postJson('/sources', body: {
    'url': site.url('/feed.xml'), 'name': 'Portail régional des opportunités', 'categories': ['scholarship', 'employment', 'tender'],
  });
  final run = await api.postJson('/search/runs', body: {
    'text': 'bourse ou emploi en données au Cameroun', 'source_ids': [source.string('id')], 'filters': {'keywords': <String>[]},
  });
  final runId = run.string('run_id');
  for (var i = 0; i < 150; i++) {
    final r = await api.getJson('/search/runs/$runId');
    if (const {'completed', 'partial', 'failed'}.contains(r.obj('run').string('status'))) break;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  final results = items(await api.getJson('/search/runs/$runId/results'));
  final opp = results.first.string('id');
  final saved = await api.postJson('/saved', body: {'opportunity_id': opp, 'priority': 'high'});
  final savedId = saved.string('id');
  final appId = saved.obj('application').string('id');
  for (final s in ['preparing', 'submitted']) {
    await api.postJson('/applications/$appId/status', body: {'status': s, if (s == 'submitted') 'submitted_on': _d(-2)});
  }
  await api.postJson('/applications/$appId/events', body: {
    'event_type': 'interview', 'title': 'Entretien avec le jury', 'scheduled_at': '${_d(9)}T10:00:00Z', 'location': 'Yaoundé',
  });
  await api.postJson('/saved/$savedId/notes', body: {'body': 'Demander une lettre de recommandation au Pr. Mballa.'});
  for (final r in results.skip(1).take(2)) {
    await api.postJson('/saved', body: {'opportunity_id': r.string('id')});
  }
  await api.postJson('/saved/$savedId/generated', body: {'doc_type': 'cover_letter', 'language': 'fr'});
  final monitor = await api.postJson('/monitors', body: {
    'name': 'Bourses et emplois data', 'filters': {'keywords': ['données']}, 'schedule_kind': 'daily',
    'schedule_expr': '08:00', 'min_score': 40, 'source_ids': [source.string('id')],
  });
  await api.postJson('/monitors/${monitor.string('id')}/run');
  final ws = await api.postJson('/workspaces', body: {'name': 'Master 2027', 'description': 'Bourses de master en données'});
  // Optional encrypted sync against a real local sync server, and an organisation sharing a workspace.
  await api.postJson('/sync/account/register',
      body: {'server_url': sync.url, 'email': 'awa@example.org', 'password': 'Mot-De-Passe-En-Ligne-2026!'});
  await api.postJson('/sync/account/verify', body: {'server_url': sync.url, 'code': await sync.code()});
  await api.postJson('/sync/account/link', body: {
    'server_url': sync.url, 'email': 'awa@example.org', 'password': 'Mot-De-Passe-En-Ligne-2026!', 'device_name': 'Bureau',
  });
  final org = await api.postJson('/orgs', body: {'name': 'Association Jeunesse Numérique', 'org_type': 'association'});
  final shared = await api.postJson('/workspaces', body: {'name': 'Subventions associatives'});
  await api.postJson('/orgs/share', body: {'kind': 'workspace', 'id': shared.string('id'), 'organization_id': org.string('id')});
  await api.postJson('/orgs/${org.string('id')}/invites', body: {'email': 'bob@example.org', 'role': 'editor'});
  await api.postJson('/sync/run');
  await api.putJson('/workspaces/${ws.string('id')}/opportunities/$opp');
  await api.postJson('/workspaces/${ws.string('id')}/notes', body: {'body': 'Comparer les conditions de mobilité.'});
  await Future<void>.delayed(const Duration(seconds: 2));
  return {'run': runId, 'opp': opp, 'saved': savedId, 'workspace': ws.string('id'), 'org': org.string('id')};
}

/// Minimal public publisher with an RSS feed and detail pages (deadlines relative to today).
class _Publisher {
  _Publisher(this._server);
  final HttpServer _server;

  static Future<_Publisher> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final p = _Publisher(server);
    server.listen(p._handle);
    return p;
  }

  String url(String path) => 'http://127.0.0.1:${_server.port}$path';
  Future<void> close() => _server.close(force: true);

  static final _items = [
    ('Bourse de master en science des données 2027 — Université de Douala',
        'L\'Université de Douala offre dix bourses complètes de 1 500 000 FCFA par an pour un master en science des '
        'données. Conditions d\'éligibilité : être titulaire d\'une licence en mathématiques ou informatique, être '
        'ressortissant d\'un pays de la CEMAC. Pièces à fournir : CV, lettre de motivation, relevés de notes.', 12),
    ('Recrutement : Analyste de données (Python, SQL) — Douala',
        'Une institution financière recrute un analyste de données à Douala en mode hybride. Profil : master en '
        'statistique, 3 ans d\'expérience, Python, SQL et Power BI. Salaire : 700 000 FCFA par mois.', 6),
    ('Appel d\'offres : plateforme de suivi des marchés publics',
        'Le ministère lance un appel d\'offres pour une plateforme logicielle de suivi. Budget estimatif : '
        '45 000 000 FCFA.', 25),
    ('Stage en analyse statistique — Yaoundé',
        'Stage de six mois en analyse statistique pour étudiants de master. Indemnité de stage : 150 000 FCFA par '
        'mois.', 40),
    ('Subvention pour projets numériques des associations',
        'Le fonds soutient les associations portant des projets numériques à impact social au Cameroun. '
        'Montant : jusqu\'à 20 000 000 FCFA.', 60),
  ];

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    final res = req.response;
    if (path == '/robots.txt') {
      res.headers.contentType = ContentType.text;
      res.write('User-agent: *\nAllow: /\n');
    } else if (path == '/feed.xml') {
      res.headers.contentType = ContentType('application', 'rss+xml', charset: 'utf-8');
      final host = 'http://127.0.0.1:${_server.port}';
      final buf = StringBuffer('<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>Portail</title>');
      for (final (i, (title, text, days)) in _items.indexed) {
        buf.write('<item><title>${_esc(title)}</title><link>$host/opp/$i.html</link><guid>tour-$i</guid>'
            '<description>${_esc(text.split('.').first)}. Date limite : ${_d(days)}.</description></item>');
      }
      res.write('$buf</channel></rss>');
    } else if (path.startsWith('/opp/')) {
      final i = int.tryParse(path.substring(5).split('.').first) ?? 0;
      final (title, text, days) = _items[i.clamp(0, _items.length - 1)];
      res.headers.contentType = ContentType.html;
      res.write('<html><body><main><h1>${_esc(title)}</h1><p>${_esc(text)}</p>'
          '<p>Date limite de candidature : ${_d(days)}.</p></main></body></html>');
    } else {
      res.statusCode = 404;
    }
    await res.close();
  }

  static String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}


/// Real sync server (sync-server/) started with the engine's Python environment, data in the tour folder.
class _SyncServer {
  _SyncServer(this._process, this.url, this._log);
  final Process _process;
  final String url;
  final StringBuffer _log;

  static Future<_SyncServer> start(Directory dataDir) async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    final root = Directory.current.parent.parent.path; // apps/desktop → repository root
    final python = Platform.isWindows ? '$root/engine/.venv/Scripts/python.exe' : '$root/engine/.venv/bin/python';
    final dbPath = '${dataDir.path}/sync.db'.replaceAll(r'\', '/');
    final process = await Process.start(
      python,
      ['-m', 'uvicorn', 'opx_sync.app:get_app', '--factory', '--host', '127.0.0.1', '--port', '$port'],
      workingDirectory: '$root/sync-server',
      environment: {
        'OPX_SYNC_DATABASE_URL': 'sqlite:///$dbPath',
        'OPX_SYNC_ARGON2_MEMORY_KIB': '8192',
        'OPX_SYNC_ARGON2_ITERATIONS': '1',
        'PYTHONUNBUFFERED': '1',
      },
    );
    final log = StringBuffer();
    process.stdout.transform(const SystemEncoding().decoder).listen(log.write);
    process.stderr.transform(const SystemEncoding().decoder).listen(log.write);
    final client = HttpClient();
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final r = await (await client.getUrl(Uri.parse('http://127.0.0.1:$port/v1/health'))).close();
        if (r.statusCode == 200) break;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    client.close();
    return _SyncServer(process, 'http://127.0.0.1:$port', log);
  }

  /// Without SMTP the server logs the verification message (self-hosting fallback, D-34).
  Future<String> code() async {
    for (var i = 0; i < 50; i++) {
      final m = RegExp(r'Code : (\S+)').allMatches(_log.toString()).lastOrNull;
      if (m != null) return m.group(1)!;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('no verification code in the sync server log');
  }

  void stop() => _process.kill();
}
