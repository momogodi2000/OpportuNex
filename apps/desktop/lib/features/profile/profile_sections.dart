import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_repository.dart';
import 'profile_repository.dart';
import 'spec_form.dart';

/// Runs a profile mutation, refreshes the profile and reports errors.
Future<void> profileAction(BuildContext context, WidgetRef ref, Future<Object?> Function(ProfileRepository) fn) async {
  try {
    await fn(ref.read(profileRepositoryProvider));
    ref.invalidate(profileProvider);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Map<String, String> _countryOptions(WidgetRef ref, String lang) => {
      for (final c in ref.watch(refCountriesProvider).valueOrNull ?? const <Json>[])
        c.string('code'): c.string(lang == 'en' ? 'name_en' : 'name_fr'),
    };

List<FieldSpec> generalFields(AppLocalizations l, Map<String, String> countries) => [
      FieldSpec('full_name', l.pfFullName, FieldKind.text, required: true),
      FieldSpec('country_code', l.pfCountry, FieldKind.choice, options: countries),
      FieldSpec('city', l.pfCity, FieldKind.text),
      FieldSpec('professional_status', l.pfStatus, FieldKind.choice, options: {
        'student': l.psStudent, 'job_seeker': l.psJobSeeker, 'employed': l.psEmployed, 'self_employed': l.psSelfEmployed,
        'freelancer': l.psFreelancer, 'entrepreneur': l.psEntrepreneur, 'researcher': l.psResearcher,
        'unemployed': l.psUnemployed, 'retired': l.psRetired, 'other': l.psOther}),
      FieldSpec('current_occupation', l.pfOccupation, FieldKind.text),
      FieldSpec('highest_education', l.pfEducationLevel, FieldKind.choice, options: {
        'none': l.edNone, 'primary': l.edPrimary, 'secondary': l.edSecondary, 'bac': l.edBac, 'bac_plus_2': l.edBac2,
        'bachelor': l.edBachelor, 'master': l.edMaster, 'doctorate': l.edDoctorate, 'postdoc': l.edPostdoc,
        'vocational': l.edVocational}),
      FieldSpec('experience_years', l.pfExperienceYears, FieldKind.number),
      FieldSpec('work_mode_pref', l.filterWorkMode, FieldKind.choice, options: {
        'remote': l.workRemote, 'hybrid': l.workHybrid, 'onsite': l.workOnsite, 'any': l.pfAnyMode}),
      FieldSpec('willing_to_relocate', l.pfRelocate, FieldKind.toggle),
      FieldSpec('contact_phone', l.pfPhone, FieldKind.text, helper: l.pfPhoneHelp),
      FieldSpec('bio', l.pfBio, FieldKind.multiline),
    ];

class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key, required this.profile});
  final Json profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final g = profile.obj('general');
    final countries = _countryOptions(ref, lang);
    final fields = generalFields(l, countries);
    return SectionCard(
      title: l.pfGeneral,
      trailing: TextButton.icon(
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.commonEdit),
        onPressed: () async {
          final values = await showSpecForm(context, title: l.pfGeneral, fields: fields, initial: g);
          if (values != null && context.mounted) await profileAction(context, ref, (r) => r.updateGeneral(values));
        },
      ),
      child: Column(children: [
        for (final f in fields)
          if (g[f.key] != null && '${g[f.key]}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 200, child: Text(f.label, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))),
                Expanded(child: Text(f.kind == FieldKind.choice ? (f.options['${g[f.key]}'] ?? '${g[f.key]}')
                    : f.kind == FieldKind.toggle ? ((g[f.key] == 1 || g[f.key] == true) ? l.commonYes : l.commonNo)
                    : Fmt.number(context, g[f.key]))),
              ]),
            ),
      ]),
    );
  }
}

/// Education, experiences, certifications and projects share one list editor.
class CollectionSection extends ConsumerWidget {
  const CollectionSection({super.key, required this.profile, required this.collection, required this.title,
      required this.fields, required this.titleOf, required this.subtitleOf});
  final Json profile;
  final String collection;
  final String title;
  final List<FieldSpec> fields;
  final String Function(Json) titleOf;
  final String Function(BuildContext, Json) subtitleOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final list = profile.list(collection);
    Future<void> edit([Json? item]) async {
      final values = await showSpecForm(context, title: title, fields: fields, initial: item);
      if (values == null || !context.mounted) return;
      await profileAction(context, ref, (r) =>
          item == null ? r.createItem(collection, values) : r.updateItem(collection, item.string('id'), values));
    }

    return SectionCard(
      title: title,
      trailing: IconButton(tooltip: l.pfAdd, icon: const Icon(Icons.add), onPressed: edit),
      child: list.isEmpty
          ? Text(l.pfNothingYet, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))
          : Column(children: [
              for (final item in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(titleOf(item)),
                  subtitle: Text(subtitleOf(context, item)),
                  onTap: () => edit(item),
                  trailing: IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmAction(context, title: l.commonDelete, message: titleOf(item),
                          confirmLabel: l.commonDelete, destructive: true);
                      if (ok && context.mounted) {
                        await profileAction(context, ref, (r) => r.deleteItem(collection, item.string('id')));
                      }
                    },
                  ),
                ),
            ]),
    );
  }
}

String _period(BuildContext context, Json item, String startKey, String endKey, {String? ongoingKey}) {
  final l = AppLocalizations.of(context);
  final start = item.str(startKey);
  final end = item.str(endKey);
  final ongoing = ongoingKey != null && item.flag(ongoingKey);
  if (start == null && end == null) return '';
  String show(String? v) => v == null ? '…' : Fmt.month(context, v);
  return '${show(start)} – ${ongoing ? l.pfOngoing : show(end)}';
}

CollectionSection educationSection(BuildContext context, Json profile) {
  final l = AppLocalizations.of(context);
  return CollectionSection(
    profile: profile, collection: 'education', title: l.pfEducation,
    fields: [
      FieldSpec('level', l.pfDegree, FieldKind.text, required: true),
      FieldSpec('field_of_study', l.pfField, FieldKind.text, required: true),
      FieldSpec('institution', l.pfInstitution, FieldKind.text, required: true),
      FieldSpec('start_date', l.pfStart, FieldKind.month),
      FieldSpec('end_date', l.pfEnd, FieldKind.month),
      FieldSpec('is_ongoing', l.pfOngoing, FieldKind.toggle),
      FieldSpec('grade', l.pfGrade, FieldKind.text),
      FieldSpec('achievements', l.pfAchievements, FieldKind.multiline),
    ],
    titleOf: (e) => '${e.string('level')} — ${e.string('field_of_study')}',
    subtitleOf: (ctx, e) => [e.string('institution'), _period(ctx, e, 'start_date', 'end_date', ongoingKey: 'is_ongoing')]
        .where((s) => s.isNotEmpty).join(' · '),
  );
}

CollectionSection experienceSection(BuildContext context, Json profile) {
  final l = AppLocalizations.of(context);
  return CollectionSection(
    profile: profile, collection: 'experiences', title: l.pfExperience,
    fields: [
      FieldSpec('job_title', l.pfJobTitle, FieldKind.text, required: true),
      FieldSpec('employer', l.pfEmployer, FieldKind.text, required: true),
      FieldSpec('employment_type', l.pfEmploymentType, FieldKind.choice, options: {
        'full_time': l.etFullTime, 'part_time': l.etPartTime, 'internship': l.etInternship, 'freelance': l.etFreelance,
        'volunteer': l.etVolunteer, 'consulting': l.etConsulting, 'other': l.psOther}),
      FieldSpec('city', l.pfCity, FieldKind.text),
      FieldSpec('start_date', l.pfStart, FieldKind.date, required: true),
      FieldSpec('end_date', l.pfEnd, FieldKind.date),
      FieldSpec('is_current', l.pfCurrentJob, FieldKind.toggle),
      FieldSpec('description', l.pfMissions, FieldKind.multiline),
    ],
    titleOf: (e) => '${e.string('job_title')} — ${e.string('employer')}',
    subtitleOf: (ctx, e) => _period(ctx, e, 'start_date', 'end_date', ongoingKey: 'is_current'),
  );
}

CollectionSection certificationSection(BuildContext context, Json profile) {
  final l = AppLocalizations.of(context);
  return CollectionSection(
    profile: profile, collection: 'certifications', title: l.pfCertifications,
    fields: [
      FieldSpec('name', l.pfCertName, FieldKind.text, required: true),
      FieldSpec('issuer', l.pfIssuer, FieldKind.text),
      FieldSpec('obtained_on', l.pfObtainedOn, FieldKind.date),
      FieldSpec('expires_on', l.pfExpiresOn, FieldKind.date),
      FieldSpec('credential_url', l.pfCredentialUrl, FieldKind.text),
    ],
    titleOf: (e) => e.string('name'),
    subtitleOf: (ctx, e) => [e.str('issuer'), e.str('obtained_on')].whereType<String>().join(' · '),
  );
}

CollectionSection projectSection(BuildContext context, Json profile) {
  final l = AppLocalizations.of(context);
  return CollectionSection(
    profile: profile, collection: 'projects', title: l.pfProjects,
    fields: [
      FieldSpec('title', l.pfProjectTitle, FieldKind.text, required: true),
      FieldSpec('description', l.pfProjectDescription, FieldKind.multiline),
      FieldSpec('stage', l.pfStage, FieldKind.choice, options: {
        'idea': l.stgIdea, 'prototype': l.stgPrototype, 'early': l.stgEarly, 'growth': l.stgGrowth,
        'scale': l.stgScale, 'established': l.stgEstablished}),
      FieldSpec('funding_min_minor', l.pfFundingMin, FieldKind.integer, helper: l.pfFundingHelp),
      FieldSpec('funding_max_minor', l.pfFundingMax, FieldKind.integer),
      FieldSpec('currency_code', l.pfCurrency, FieldKind.choice, options: const {'XAF': 'XAF', 'EUR': 'EUR', 'USD': 'USD'}),
      FieldSpec('beneficiaries', l.pfBeneficiaries, FieldKind.text),
      FieldSpec('legal_status', l.pfLegalStatus, FieldKind.text),
      FieldSpec('timeline_months', l.pfTimeline, FieldKind.integer),
    ],
    titleOf: (e) => e.string('title'),
    subtitleOf: (ctx, e) => e.str('funding_min_minor') == null && e.integer('funding_min_minor') == null
        ? (e.str('stage') ?? '')
        : Fmt.money(ctx, e.integer('funding_min_minor'), e.integer('funding_max_minor'), e.str('currency_code') ?? 'XAF'),
  );
}

class SkillsLanguagesSection extends ConsumerWidget {
  const SkillsLanguagesSection({super.key, required this.profile});
  final Json profile;

  static const cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'native'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final skills = profile.list('skills');
    final languages = profile.list('languages');
    final allLanguages = ref.watch(refLanguagesProvider).valueOrNull ?? const <Json>[];
    final lang = Localizations.localeOf(context).languageCode;
    List<Json> skillPayload(List<Json> list) =>
        [for (final s in list) {'name': s.string('name'), 'level': s.integer('level'), 'is_primary': s.flag('is_primary')}];

    return SectionCard(
      title: l.pfSkillsLanguages,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.pfSkills, style: context.text.labelLarge),
        const SizedBox(height: Space.sm),
        Wrap(spacing: Space.xs, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final s in skills)
            InputChip(
              avatar: s.flag('is_primary') ? const Icon(Icons.star, size: 16) : null,
              label: Text(s.string('name')),
              tooltip: l.pfSkillPrimaryToggle,
              onPressed: () => profileAction(context, ref, (r) => r.setSkills([
                    for (final x in skillPayload(skills))
                      x['name'] == s.string('name') ? {...x, 'is_primary': !(x['is_primary'] as bool)} : x,
                  ])),
              onDeleted: () => profileAction(context, ref,
                  (r) => r.setSkills(skillPayload(skills.where((x) => x.string('name') != s.string('name')).toList()))),
            ),
          _SkillAdder(onAdd: (name) => profileAction(context, ref,
              (r) => r.setSkills([...skillPayload(skills), {'name': name}]))),
        ]),
        const SizedBox(height: Space.lg),
        Text(l.pfLanguages, style: context.text.labelLarge),
        const SizedBox(height: Space.sm),
        for (final lg in languages)
          Row(children: [
            SizedBox(width: 160, child: Text(allLanguages.where((x) => x.str('code') == lg.str('language_code'))
                .map((x) => x.string(lang == 'en' ? 'name_en' : 'name_fr')).firstOrNull ?? lg.string('language_code'))),
            DropdownButton<String>(
              value: lg.string('cefr_level'),
              items: [for (final c in cefr) DropdownMenuItem(value: c, child: Text(c == 'native' ? l.pfNative : c))],
              onChanged: (v) => profileAction(context, ref, (r) => r.setLanguages([
                    for (final x in languages)
                      {'language_code': x.string('language_code'),
                        'cefr_level': x.str('language_code') == lg.str('language_code') ? v : x.string('cefr_level')},
                  ])),
            ),
            IconButton(
              tooltip: l.commonDelete,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => profileAction(context, ref, (r) => r.setLanguages([
                    for (final x in languages)
                      if (x.str('language_code') != lg.str('language_code'))
                        {'language_code': x.string('language_code'), 'cefr_level': x.string('cefr_level')},
                  ])),
            ),
          ]),
        MenuAnchor(
          menuChildren: [
            for (final x in allLanguages.where((a) => !languages.any((b) => b.str('language_code') == a.str('code'))))
              MenuItemButton(
                onPressed: () => profileAction(context, ref, (r) => r.setLanguages([
                      for (final y in languages) {'language_code': y.string('language_code'), 'cefr_level': y.string('cefr_level')},
                      {'language_code': x.string('code'), 'cefr_level': 'B1'},
                    ])),
                child: Text(x.string(lang == 'en' ? 'name_en' : 'name_fr')),
              ),
          ],
          builder: (context, c, _) => TextButton.icon(
            onPressed: () => c.isOpen ? c.close() : c.open(),
            icon: const Icon(Icons.add),
            label: Text(l.pfAddLanguage),
          ),
        ),
      ]),
    );
  }
}

class _SkillAdder extends ConsumerStatefulWidget {
  const _SkillAdder({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  ConsumerState<_SkillAdder> createState() => _SkillAdderState();
}

class _SkillAdderState extends ConsumerState<_SkillAdder> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: 260,
      child: Autocomplete<String>(
        optionsBuilder: (v) async {
          if (v.text.trim().length < 2) return const [];
          final found = await ref.read(profileRepositoryProvider).skills(v.text.trim());
          return found.map((s) => s.string('name'));
        },
        onSelected: widget.onAdd,
        fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(isDense: true, hintText: l.pfAddSkill, prefixIcon: const Icon(Icons.add, size: 18)),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) widget.onAdd(v.trim());
            controller.clear();
          },
        ),
      ),
    );
  }
}

class ObjectivesSection extends ConsumerStatefulWidget {
  const ObjectivesSection({super.key, required this.profile});
  final Json profile;

  @override
  ConsumerState<ObjectivesSection> createState() => _ObjectivesSectionState();
}

class _ObjectivesSectionState extends ConsumerState<ObjectivesSection> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final all = ref.watch(refObjectivesProvider).valueOrNull ?? const <Json>[];
    final obj = widget.profile.obj('objectives');
    final selected = obj.list('items').map((o) => o.integer('objective_id')!).toList();
    final custom = obj.list('custom').map((c) => c.string('label')).toList();
    Future<void> save(List<int> ids, List<String> c) => profileAction(context, ref, (r) => r.setObjectives(ids, c));
    return SectionCard(
      title: l.pfObjectives,
      subtitle: l.pfObjectivesHelp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (final o in all)
            FilterChip(
              label: Text(o.string(lang == 'en' ? 'name_en' : 'name_fr')),
              selected: selected.contains(o.integer('id')),
              onSelected: (v) => save(v ? [...selected, o.integer('id')!] : ([...selected]..remove(o.integer('id'))), custom),
            ),
        ]),
        const SizedBox(height: Space.md),
        Wrap(spacing: Space.xs, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final c in custom) InputChip(label: Text(c), onDeleted: () => save(selected, [...custom]..remove(c))),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _custom,
              decoration: InputDecoration(isDense: true, hintText: l.pfCustomObjective),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                unawaited(save(selected, [...custom, v.trim()]));
                _custom.clear();
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

class LinksLocationsSection extends ConsumerWidget {
  const LinksLocationsSection({super.key, required this.profile});
  final Json profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final links = profile.list('links');
    final locations = profile.list('preferred_locations');
    final countries = _countryOptions(ref, lang);
    final kinds = {'linkedin': 'LinkedIn', 'github': 'GitHub', 'gitlab': 'GitLab', 'portfolio': l.pfPortfolio,
      'website': l.pfWebsite, 'orcid': 'ORCID', 'other': l.psOther};
    return SectionCard(
      title: l.pfLinksLocations,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.pfLinks, style: context.text.labelLarge),
        for (final link in links)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: Text(link.string('url')),
            subtitle: Text(kinds[link.string('kind')] ?? link.string('kind')),
            trailing: IconButton(
              tooltip: l.commonDelete,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => profileAction(context, ref, (r) => r.setLinks([
                    for (final x in links) if (x.str('url') != link.str('url')) {'kind': x.string('kind'), 'url': x.string('url')},
                  ])),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add_link),
          label: Text(l.pfAddLink),
          onPressed: () async {
            final v = await showSpecForm(context, title: l.pfAddLink, fields: [
              FieldSpec('kind', l.pfLinkKind, FieldKind.choice, required: true, options: kinds),
              const FieldSpec('url', 'URL', FieldKind.text, required: true, helper: 'https://…'),
            ]);
            if (v == null || !context.mounted) return;
            await profileAction(context, ref, (r) => r.setLinks([
                  for (final x in links) {'kind': x.string('kind'), 'url': x.string('url')},
                  v,
                ]));
          },
        ),
        const Divider(height: Space.xl),
        Text(l.pfPreferredLocations, style: context.text.labelLarge),
        Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (final loc in locations)
            InputChip(
              label: Text(loc.str('region_label') ?? countries[loc.str('country_code')] ?? loc.string('country_code')),
              onDeleted: () => profileAction(context, ref, (r) => r.setLocations([
                    for (final x in locations)
                      if (x != loc) {'country_code': x.str('country_code'), 'region_label': x.str('region_label')},
                  ])),
            ),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: () => profileAction(context, ref, (r) => r.setLocations([
                      for (final x in locations) {'country_code': x.str('country_code'), 'region_label': x.str('region_label')},
                      {'region_label': 'Afrique centrale'},
                    ])),
                child: Text(l.pfRegionCentralAfrica),
              ),
              for (final c in countries.entries)
                MenuItemButton(
                  onPressed: () => profileAction(context, ref, (r) => r.setLocations([
                        for (final x in locations) {'country_code': x.str('country_code'), 'region_label': x.str('region_label')},
                        {'country_code': c.key},
                      ])),
                  child: Text(c.value),
                ),
            ],
            builder: (context, c, _) => ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(l.filterAdd),
              onPressed: () => c.isOpen ? c.close() : c.open(),
            ),
          ),
        ]),
      ]),
    );
  }
}

class OrganizationSection extends ConsumerWidget {
  const OrganizationSection({super.key, required this.profile});
  final Json profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final org = profile.objOrNull('organization');
    final fields = [
      FieldSpec('name', l.orgName, FieldKind.text, required: true),
      FieldSpec('org_type', l.orgType, FieldKind.choice, required: true, options: {
        'association': l.orgAssociation, 'ngo': l.orgNgo, 'sme': l.orgSme, 'startup': l.orgStartup,
        'cooperative': l.orgCooperative, 'public': l.orgPublic, 'academic': l.orgAcademic, 'other': l.psOther}),
      FieldSpec('legal_status', l.pfLegalStatus, FieldKind.text),
      FieldSpec('registration_no', l.orgRegistration, FieldKind.text),
      FieldSpec('country_code', l.pfCountry, FieldKind.choice, options: _countryOptions(ref, lang)),
      FieldSpec('sector', l.orgSector, FieldKind.text),
      FieldSpec('annual_budget_band', l.orgBudget, FieldKind.choice, options: {
        'lt_10m_xaf': '< 10 M XAF', '10m_50m_xaf': '10–50 M XAF', '50m_250m_xaf': '50–250 M XAF', 'gt_250m_xaf': '> 250 M XAF'}),
      FieldSpec('website', l.pfWebsite, FieldKind.text),
      FieldSpec('description', l.pfProjectDescription, FieldKind.multiline),
    ];
    return SectionCard(
      title: l.orgTitle,
      subtitle: l.orgHelp,
      trailing: Wrap(children: [
        TextButton(
          onPressed: () async {
            final v = await showSpecForm(context, title: l.orgTitle, fields: fields, initial: org);
            if (v != null && context.mounted) await profileAction(context, ref, (r) => r.setOrganization(v));
          },
          child: Text(org == null ? l.pfAdd : l.commonEdit),
        ),
        if (org != null)
          IconButton(tooltip: l.commonDelete, icon: const Icon(Icons.delete_outline),
              onPressed: () => profileAction(context, ref, (r) => r.deleteOrganization())),
      ]),
      child: org == null
          ? Text(l.orgNone, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))
          : Text('${org.string('name')} · ${org.string('org_type')}${org.str('sector') == null ? '' : ' · ${org.string('sector')}'}'),
    );
  }
}

class SummarySection extends ConsumerStatefulWidget {
  const SummarySection({super.key, required this.profile});
  final Json profile;

  @override
  ConsumerState<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends ConsumerState<SummarySection> {
  late final _c = TextEditingController(text: widget.profile.obj('general').str('summary_text') ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final approved = widget.profile.obj('general').flag('summary_approved');
    return SectionCard(
      title: l.pfSummary,
      subtitle: l.pfSummaryHelp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _c, minLines: 3, maxLines: 8),
        const SizedBox(height: Space.sm),
        Wrap(spacing: Space.sm, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_fix_high),
            label: Text(l.pfSummaryGenerate),
            onPressed: () async {
              final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';
              final text = await ref.read(profileRepositoryProvider).generateSummary(lang);
              setState(() => _c.text = text);
            },
          ),
          FilledButton.icon(
            icon: Icon(approved ? Icons.verified : Icons.check),
            label: Text(approved ? l.pfSummaryApproved : l.pfSummaryApprove),
            onPressed: () => profileAction(context, ref, (r) => r.saveSummary(_c.text, true)),
          ),
        ]),
      ]),
    );
  }
}
