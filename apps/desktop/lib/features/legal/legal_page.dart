import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

/// Terms of use and privacy policy, bundled with the app and readable offline (EF-18.09).
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
          title: Text(l.aboutTermsPrivacy),
          bottom: TabBar(tabs: [Tab(text: l.legalTerms), Tab(text: l.legalPrivacy)]),
        ),
        body: TabBarView(children: [
          _MarkdownAsset('assets/legal/terms_$lang.md'),
          _MarkdownAsset('assets/legal/privacy_$lang.md'),
        ]),
      ),
    );
  }
}

class _MarkdownAsset extends StatelessWidget {
  const _MarkdownAsset(this.path);
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(path),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(error: snap.error!);
        if (!snap.hasData) return const LoadingState();
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SelectionArea(child: SimpleMarkdown(snap.data!)),
          ),
        );
      },
    );
  }
}

/// Minimal Markdown renderer (headings, paragraphs, bullet lists) for bundled texts.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key, this.padding = const EdgeInsets.all(Space.xxl)});
  final String source;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        blocks.add(const SizedBox(height: Space.sm));
      } else if (line.startsWith('# ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Semantics(header: true, child: Text(line.substring(2), style: context.text.headlineSmall)),
        ));
      } else if (line.startsWith('## ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
          child: Semantics(header: true, child: Text(line.substring(3), style: context.text.titleMedium)),
        ));
      } else if (line.startsWith('- ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: Space.md, bottom: Space.xs),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•  '),
            Expanded(child: Text(line.substring(2), style: context.text.bodyMedium)),
          ]),
        ));
      } else {
        blocks.add(Text(line, style: context.text.bodyMedium));
      }
    }
    return ListView(padding: padding, children: blocks);
  }
}
