import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/engine/engine_supervisor.dart';
import 'core/prefs/ui_prefs.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class OpportunexApp extends ConsumerStatefulWidget {
  const OpportunexApp({super.key, this.startEngine = true});

  /// Widget tests disable the real process launch.
  final bool startEngine;

  @override
  ConsumerState<OpportunexApp> createState() => _OpportunexAppState();
}

class _OpportunexAppState extends ConsumerState<OpportunexApp> {
  @override
  void initState() {
    super.initState();
    if (widget.startEngine) {
      unawaited(Future.microtask(() => ref.read(engineSupervisorProvider.notifier).start()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    return MaterialApp.router(
      title: 'Opportunex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
