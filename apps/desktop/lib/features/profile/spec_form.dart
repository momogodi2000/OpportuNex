import 'package:flutter/material.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

enum FieldKind { text, multiline, number, integer, date, month, choice, toggle }

/// Declarative description of one form field.
class FieldSpec {
  const FieldSpec(this.key, this.label, this.kind, {this.required = false, this.options = const {}, this.helper});
  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final Map<String, String> options;
  final String? helper;
}

/// Edits a JSON map described by [fields]; returns the new map on save.
Future<Json?> showSpecForm(BuildContext context, {required String title, required List<FieldSpec> fields, Json? initial}) =>
    showDialog<Json>(context: context, builder: (_) => _SpecDialog(title: title, fields: fields, initial: initial ?? const {}));

class _SpecDialog extends StatefulWidget {
  const _SpecDialog({required this.title, required this.fields, required this.initial});
  final String title;
  final List<FieldSpec> fields;
  final Json initial;

  @override
  State<_SpecDialog> createState() => _SpecDialogState();
}

class _SpecDialogState extends State<_SpecDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _values = Map.of(widget.initial);
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.fields)
      if (const {FieldKind.text, FieldKind.multiline, FieldKind.number, FieldKind.integer}.contains(f.kind))
        f.key: TextEditingController(text: _values[f.key] == null ? '' : '${_values[f.key]}'),
  };

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.kind) {
        case FieldKind.text || FieldKind.multiline:
          final v = _text[f.key]!.text.trim();
          out[f.key] = v.isEmpty ? null : v;
        case FieldKind.number:
          out[f.key] = double.tryParse(_text[f.key]!.text.replaceAll(',', '.'));
        case FieldKind.integer:
          out[f.key] = int.tryParse(_text[f.key]!.text.replaceAll(RegExp(r'[\s.]'), ''));
        default:
          out[f.key] = _values[f.key];
      }
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.validationRequired : null;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: switch (f.kind) {
                    FieldKind.text || FieldKind.number || FieldKind.integer => TextFormField(
                        controller: _text[f.key],
                        keyboardType: f.kind == FieldKind.text ? TextInputType.text : TextInputType.number,
                        decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, helperText: f.helper),
                        validator: f.required ? required : null,
                      ),
                    FieldKind.multiline => TextFormField(
                        controller: _text[f.key],
                        minLines: 3,
                        maxLines: 8,
                        decoration: InputDecoration(labelText: f.label, alignLabelWithHint: true, helperText: f.helper),
                        validator: f.required ? required : null,
                      ),
                    FieldKind.choice => DropdownButtonFormField<String>(
                        initialValue: f.options.containsKey(_values[f.key]) ? _values[f.key] as String : null,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label),
                        items: [
                          if (!f.required) DropdownMenuItem(child: Text(l.commonNotSpecified)),
                          for (final o in f.options.entries) DropdownMenuItem(value: o.key, child: Text(o.value)),
                        ],
                        validator: f.required ? (v) => v == null ? l.validationRequired : null : null,
                        onChanged: (v) => setState(() => _values[f.key] = v),
                      ),
                    FieldKind.toggle => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.label),
                        value: _values[f.key] == true || _values[f.key] == 1,
                        onChanged: (v) => setState(() => _values[f.key] = v),
                      ),
                    FieldKind.date || FieldKind.month => _DateField(
                        label: f.required ? '${f.label} *' : f.label,
                        value: _values[f.key] as String?,
                        monthOnly: f.kind == FieldKind.month,
                        requiredField: f.required,
                        onChanged: (v) => setState(() => _values[f.key] = v),
                      ),
                  },
                ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}

class _DateField extends FormField<String> {
  _DateField({required String label, required String? value, required bool monthOnly, required bool requiredField,
      required ValueChanged<String?> onChanged})
      : super(
          initialValue: value,
          validator: (v) => requiredField && (v == null || v.isEmpty) ? '!' : null,
          builder: (state) {
            final context = state.context;
            final l = AppLocalizations.of(context);
            final current = state.value;
            return InputDecorator(
              decoration: InputDecoration(labelText: label, errorText: state.hasError ? l.validationRequired : null),
              child: Row(children: [
                Expanded(child: Text(current ?? l.commonNotSpecified)),
                IconButton(
                  tooltip: l.commonEdit,
                  icon: const Icon(Icons.event),
                  onPressed: () async {
                    final initial = DateTime.tryParse(current?.length == 7 ? '$current-01' : current ?? '') ?? DateTime.now();
                    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1950),
                        lastDate: DateTime(DateTime.now().year + 10));
                    if (d == null) return;
                    final iso = d.toIso8601String().substring(0, monthOnly ? 7 : 10);
                    state.didChange(iso);
                    onChanged(iso);
                  },
                ),
                if (current != null)
                  IconButton(tooltip: l.commonDelete, icon: const Icon(Icons.clear), onPressed: () {
                    state.didChange(null);
                    onChanged(null);
                  }),
              ]),
            );
          },
        );
}
