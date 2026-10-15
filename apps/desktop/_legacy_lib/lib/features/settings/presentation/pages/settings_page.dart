import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLoc.of(context);
    final categories = [
      loc.get('account'),
      loc.get('appearance'),
      loc.get('privacy'),
      loc.get('backups'),
      loc.get('matching'),
      loc.get('notifications'),
      loc.get('network'),
      'IA',
      'Sources',
      loc.get('about'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('settings')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                return ListTile(
                  title: Text(
                    categories[index],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFF97316)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFFF97316).withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildCategoryContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategoryIndex) {
      case 0:
        return _buildAccountSettings();
      case 1:
        return _buildAppearanceSettings();
      case 2:
        return _buildPrivacySettings();
      case 3:
        return _buildBackupSettings();
      case 4:
        return _buildMatchSettings();
      case 5:
        return _buildNotificationSettings();
      case 6:
        return _buildNetworkSettings();
      case 7:
        return _buildAISettings();
      case 8:
        return _buildSourcesSettings();
      case 9:
        return _buildAboutSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAccountSettings() {
    return ListView(
      children: [
        Text(
          'Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 24),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Changer le mot de passe'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Phrase de récupération'),
          subtitle: Text('Afficher ou régénérer (Attention)'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.screen_lock_portrait),
          title: Text('Verrouiller la session'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Déconnexion'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Colors.red),
          title: Text(
            'Supprimer le compte',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    final settings = ref.watch(settingsProvider);
    final loc = AppLoc.of(context);
    String themeVal = 'system';
    if (settings.themeMode == ThemeMode.light) themeVal = 'light';
    if (settings.themeMode == ThemeMode.dark) themeVal = 'dark';
    return ListView(
      children: [
        Text(
          loc.get('appearance'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(loc.get('theme')),
        Row(
          children: [
            Radio(
              value: 'light',
              groupValue: themeVal,
              onChanged: (v) {
                ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.light);
              },
            ),
            Text(loc.get('light')),
            Radio(
              value: 'dark',
              groupValue: themeVal,
              onChanged: (v) {
                ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.dark);
              },
            ),
            Text(loc.get('dark')),
            Radio(
              value: 'system',
              groupValue: themeVal,
              onChanged: (v) {
                ref
                    .read(settingsProvider.notifier)
                    .updateThemeMode(ThemeMode.system);
              },
            ),
            Text(loc.get('system')),
          ],
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: settings.locale.languageCode,
          decoration: InputDecoration(
            labelText: loc.get('language'),
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('Français')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) {
            if (v != null) {
              ref.read(settingsProvider.notifier).updateLocale(Locale(v));
            }
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return ListView(
      children: [
        Text(
          'Confidentialité',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.receipt_long),
          title: Text('Journal de sécurité'),
          onTap: () {},
        ),
        SwitchListTile(
          title: Text('Consentement au suivi analytique'),
          value: true,
          onChanged: (v) {},
        ),
        ListTile(
          leading: Icon(Icons.download),
          title: Text('Exporter mes données'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.cleaning_services),
          title: Text('Purger les opportunités'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return ListView(
      children: [
        Text(
          'Sauvegardes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        Text("Dernière sauvegarde: Aujourd'hui à 10:00 (Succès)"),
        Text('Prochaine sauvegarde: Demain à 02:00'),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.backup),
          label: Text('Créer une sauvegarde maintenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        Text('Historique', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('backup_20261002.zip'),
          subtitle: Text('2 oct. 2026 - 15MB'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.restore), onPressed: () {}),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchSettings() {
    return ListView(
      children: [
        Text(
          'Correspondance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        Text('Poids des critères (Total: 100%)'),
        SizedBox(height: 16),
        _buildSliderRow('Compétences', 40),
        _buildSliderRow('Localisation', 20),
        _buildSliderRow('Salaire', 10),
        _buildSliderRow('Expérience', 20),
        _buildSliderRow('Langues', 10),
        SizedBox(height: 16),
        Text("Seuil minimum d'affichage"),
        Slider(
          value: 50,
          min: 0,
          max: 100,
          divisions: 100,
          label: '50%',
          activeColor: const Color(0xFFF97316),
          onChanged: (v) {},
        ),
        TextButton(onPressed: () {}, child: Text('Réinitialiser les poids')),
      ],
    );
  }

  Widget _buildSliderRow(String label, double value) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: const Color(0xFF22C55E),
            onChanged: (v) {},
          ),
        ),
        SizedBox(width: 40, child: Text('${value.toInt()}%')),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return ListView(
      children: [
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text('Rappels de deadline'),
          subtitle: Text("Notifier avant l'expiration"),
          value: true,
          onChanged: (v) {},
        ),
        DropdownButtonFormField<int>(
          initialValue: 3,
          decoration: const InputDecoration(
            labelText: 'Jours avant',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 jour')),
            DropdownMenuItem(value: 3, child: Text('3 jours')),
            DropdownMenuItem(value: 7, child: Text('7 jours')),
            DropdownMenuItem(value: 14, child: Text('14 jours')),
          ],
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: Text('Alertes des veilles'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(title: Text('Sons'), value: false, onChanged: (v) {}),
        SwitchListTile(
          title: Text('Notifications de bureau'),
          value: true,
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildNetworkSettings() {
    return ListView(
      children: [
        Text(
          'Réseau',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        Text('Proxy', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Hôte',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: 'HTTP',
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'HTTP', child: Text('HTTP')),
                  DropdownMenuItem(value: 'SOCKS5', child: Text('SOCKS5')),
                ],
                onChanged: (v) {},
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Text('Max requêtes simultanées'),
        Slider(
          value: 8,
          min: 1,
          max: 16,
          divisions: 15,
          label: '8',
          activeColor: const Color(0xFF22C55E),
          onChanged: (v) {},
        ),
        SizedBox(height: 16),
        Text('Timeout (secondes)'),
        Slider(
          value: 30,
          min: 10,
          max: 120,
          divisions: 110,
          label: '30s',
          activeColor: const Color(0xFFF97316),
          onChanged: (v) {},
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'User-Agent',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(
            text: 'Mozilla/5.0 (OpportuNex/1.0)',
          ),
        ),
      ],
    );
  }

  Widget _buildAISettings() {
    return ListView(
      children: [
        Text(
          'Intelligence Artificielle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.add),
          label: Text('Ajouter un fournisseur IA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OpenAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(icon: Icon(Icons.edit), onPressed: () {}),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                Text('Modèle: gpt-4o-mini'),
                Text('Clé API: sk-...abcd'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Tester la connexion'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesSettings() {
    return ListView(
      children: [
        Text(
          'Sources',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.add_link),
          label: Text('Ajouter une source personnalisée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text('Emploi.cm'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: Text('LinkedIn Afrique'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: Text('ReliefWeb'),
          value: false,
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildAboutSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "À propos d'OpportuNex",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        Text('Version: 1.0.0 (Production)'),
        SizedBox(height: 8),
        Text('Développé par: ING Momo Godi Yvan'),
        SizedBox(height: 8),
        Text('Financé par: Association PROTEGE QV'),
        SizedBox(height: 8),
        Text('Licence: GNU AGPL v3'),
        SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.code),
          label: Text('Code source sur GitHub'),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.history),
          label: Text('Journal des modifications (Changelog)'),
        ),
      ],
    );
  }
}
