import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/layout.dart';
import '../../l10n/app_localizations.dart';
import 'maintenance_repository.dart';

/// Version, publisher, author, licence and third-party notices (master prompt §9).
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final engine = ref.watch(versionProvider).valueOrNull;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(Space.xxl),
          children: [
            SectionCard(
              child: Row(children: [
                const AppLogo(size: 72),
                const SizedBox(width: Space.xl),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.appName, style: context.text.headlineSmall),
                    Text(l.slogan, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
                    const SizedBox(height: Space.sm),
                    Text('${l.aboutVersion} ${AppInfo.version}'
                        '${engine == null ? '' : ' · ${l.aboutEngine} ${engine['engine_version']} · ${l.aboutSchema} ${engine['schema_revision']}'}'),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: Space.xl),
            SectionCard(
              title: l.aboutCredits,
              child: Column(children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.business), title: Text(l.aboutPublisher), subtitle: const Text(AppInfo.publisher)),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline), title: Text(l.aboutAuthor), subtitle: const Text(AppInfo.author)),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.copyright), title: Text(l.aboutCopyright), subtitle: const Text(AppInfo.copyright)),
              ]),
            ),
            const SizedBox(height: Space.xl),
            SectionCard(
              title: l.aboutLicense,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.aboutLicenseBody),
                const SizedBox(height: Space.lg),
                Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('https://www.gnu.org/licenses/agpl-3.0.html')),
                    icon: const Icon(Icons.gavel_outlined),
                    label: const Text('GNU AGPL v3'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(AppInfo.sourceUrl)),
                    icon: const Icon(Icons.code),
                    label: Text(l.aboutSourceCode),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: l.appName,
                      applicationVersion: AppInfo.version,
                      applicationLegalese: AppInfo.copyright,
                    ),
                    icon: const Icon(Icons.library_books_outlined),
                    label: Text(l.aboutThirdParty),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/legal'),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: Text(l.aboutTermsPrivacy),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
