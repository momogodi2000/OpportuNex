import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Standard page frame inside the shell: title row with actions, then scrollable content.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.scrollable = true,
    this.maxWidth = Layout.contentMaxWidth,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool scrollable;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          for (final a in actions) Padding(padding: const EdgeInsets.only(left: Space.sm), child: a),
        ],
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.xxl),
      child: child,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: scrollable
            ? ListView(children: [header, body])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, Expanded(child: body)]),
      ),
    );
  }
}

/// Card with an optional title row, used for grouped settings and detail sections.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.subtitle, this.trailing, required this.child, this.padding});

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(title!, style: context.text.titleMedium)),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.xs),
                            child: Text(subtitle!,
                                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: Space.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Centered card used by full-screen flows (sign-in, registration, diagnostics).
class CenteredPanel extends StatelessWidget {
  const CenteredPanel({super.key, required this.child, this.maxWidth = Layout.formMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(child: Padding(padding: const EdgeInsets.all(Space.xxl), child: child)),
          ),
        ),
      ),
    );
  }
}
