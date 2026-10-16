import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// One entry of the command palette (EF-18.13).
class PaletteCommand {
  const PaletteCommand(this.label, this.icon, this.run, {this.shortcut, this.keywords = ''});
  final String label;
  final IconData icon;
  final VoidCallback run;
  final String? shortcut;
  final String keywords;
}

/// Keyboard-first launcher (Ctrl+K): type to filter, arrows to move, Enter to run, Esc to close.
Future<void> showCommandPalette(BuildContext context, List<PaletteCommand> commands) async {
  final chosen = await showDialog<PaletteCommand>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _Palette(commands: commands),
  );
  chosen?.run();
}

String _fold(String s) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿ';
  const to = 'aaaaaceeeeiiiinooooouuuuy';
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}

class _Palette extends StatefulWidget {
  const _Palette({required this.commands});
  final List<PaletteCommand> commands;

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final _query = TextEditingController();
  int _index = 0;

  List<PaletteCommand> get _matches {
    final words = _fold(_query.text).split(' ').where((w) => w.isNotEmpty);
    return widget.commands.where((c) {
      final hay = _fold('${c.label} ${c.keywords}');
      return words.every(hay.contains);
    }).toList();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final n = _matches.length;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown && n > 0) {
      setState(() => _index = (_index + 1) % n);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp && n > 0) {
      setState(() => _index = (_index - 1 + n) % n);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final matches = _matches;
    final index = matches.isEmpty ? 0 : _index.clamp(0, matches.length - 1);
    return Dialog(
      alignment: const Alignment(0, -0.6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 460),
        child: Focus(
          onKeyEvent: _onKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.paletteHint),
                onChanged: (_) => setState(() => _index = 0),
                onSubmitted: (_) {
                  if (matches.isNotEmpty) Navigator.pop(context, matches[index]);
                },
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: matches.isEmpty
                  ? Padding(padding: const EdgeInsets.all(Space.xl), child: Text(l.paletteEmpty))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: matches.length,
                      itemBuilder: (_, i) {
                        final c = matches[i];
                        return ListTile(
                          selected: i == index,
                          selectedTileColor: context.colors.secondaryContainer,
                          leading: Icon(c.icon),
                          title: Text(c.label),
                          trailing: c.shortcut == null ? null : _Keys(c.shortcut!),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys(this.keys);
  final String keys;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xxs),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Text(keys, style: context.text.labelSmall),
      );
}

/// F1 / Ctrl+/ : the list of keyboard shortcuts.
Future<void> showShortcutsHelp(BuildContext context) {
  final l = AppLocalizations.of(context);
  final rows = [
    ('Ctrl+K', l.shortcutPalette),
    ('Ctrl+F', l.shortcutSearch),
    ('Ctrl+1 … Ctrl+8', l.shortcutSections),
    ('Ctrl+L', l.authLock),
    ('F1 · Ctrl+/', l.shortcutHelp),
    ('Échap / Esc', l.shortcutClose),
  ];
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.shortcutsTitle),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (keys, label) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(children: [
                SizedBox(width: 150, child: _Keys(keys)),
                Expanded(child: Text(label)),
              ]),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonClose))],
    ),
  );
}
