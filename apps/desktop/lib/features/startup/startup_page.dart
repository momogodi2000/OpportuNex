import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/engine/engine_supervisor.dart';
import '../../core/platform/app_paths.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../l10n/app_localizations.dart';

/// Splash while the engine starts, diagnostics screen if it cannot (arch §3.4 point 4).
class StartupPage extends ConsumerWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(engineSupervisorProvider);
    final l = AppLocalizations.of(context);
    if (status.phase != EngineRunState.failed) {
      final message = status.phase == EngineRunState.restarting ? l.startupRestarting(status.attempt) : l.startupStarting;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandHeader(),
              const SizedBox(height: Space.xxl),
              const SizedBox(width: 220, child: LinearProgressIndicator()),
              const SizedBox(height: Space.md),
              Semantics(liveRegion: true, child: Text(message, style: context.text.bodyMedium)),
            ],
          ),
        ),
      );
    }
    return _Diagnostics(status: status);
  }
}

class _Diagnostics extends ConsumerWidget {
  const _Diagnostics({required this.status});
  final EngineStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final explanation = switch (status.failure) {
      EngineFailure.notFound => l.diagNotFound,
      EngineFailure.alreadyRunning => l.diagAlreadyRunning,
      EngineFailure.handshakeTimeout => l.diagHandshake,
      EngineFailure.crashed => l.diagCrashed,
      EngineFailure.healthTimeout || null => l.diagHealth,
    };
    final details = [if (status.detail != null) status.detail!, ...status.logTail].join('\n');
    return CenteredPanel(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.report_gmailerrorred, color: context.colors.error, size: 32),
            const SizedBox(width: Space.md),
            Expanded(child: Text(l.diagTitle, style: context.text.titleLarge)),
          ]),
          const SizedBox(height: Space.lg),
          Text(explanation, style: context.text.bodyLarge),
          const SizedBox(height: Space.xl),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.diagDetails),
            children: [
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: Radii.control,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(details, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: details));
                    if (context.mounted) showSuccess(context, l.commonCopied);
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l.commonCopy),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final dir = Directory(AppPaths.logsDir());
                  await dir.create(recursive: true);
                  await launchUrl(Uri.file(dir.path));
                },
                icon: const Icon(Icons.folder_open),
                label: Text(l.diagExportLogs),
              ),
              FilledButton.icon(
                onPressed: () => ref.read(engineSupervisorProvider.notifier).retry(),
                icon: const Icon(Icons.restart_alt),
                label: Text(l.diagRetry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
