import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'COMPTE',
    'APPARENCE',
    'CONFIDENTIALITÉ',
    'SAUVEGARDES',
    'CORRESPONDANCE',
    'NOTIFICATIONS',
    'RÉSEAU',
    'IA',
    'SOURCES',
    'À PROPOS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Color(0xFF0D1B3E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                return ListTile(
                  title: Text(
                    _categories[index],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFF97316)
                          : const Color(0xFF0D1B3E),
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
        const Text(
          'Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Changer le mot de passe'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Phrase de récupération'),
          subtitle: const Text('Afficher ou régénérer (Attention)'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.screen_lock_portrait),
          title: const Text('Verrouiller la session'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Déconnexion'),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            'Supprimer le compte',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return ListView(
      children: [
        const Text(
          'Apparence',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Thème'),
        Row(
          children: [
            Radio(value: 'clair', groupValue: 'clair', onChanged: (v) {}),
            const Text('Clair'),
            Radio(value: 'sombre', groupValue: 'clair', onChanged: (v) {}),
            const Text('Sombre'),
            Radio(value: 'auto', groupValue: 'clair', onChanged: (v) {}),
            const Text('Automatique'),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: 'fr',
          decoration: const InputDecoration(
            labelText: 'Langue',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'fr', child: Text('Français')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        const Text('Taille de police'),
        Slider(
          value: 1,
          min: 0,
          max: 3,
          divisions: 3,
          label: 'Taille',
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Mode compact pour les listes'),
          value: false,
          onChanged: (v) {},
          activeColor: const Color(0xFF22C55E),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return ListView(
      children: [
        const Text(
          'Confidentialité',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('Journal de sécurité'),
          onTap: () {},
        ),
        SwitchListTile(
          title: const Text('Consentement au suivi analytique'),
          value: true,
          onChanged: (v) {},
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Exporter mes données'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('Purger les opportunités'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return ListView(
      children: [
        const Text(
          'Sauvegardes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Dernière sauvegarde: Aujourd'hui à 10:00 (Succès)"),
        const Text('Prochaine sauvegarde: Demain à 02:00'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.backup),
          label: const Text('Créer une sauvegarde maintenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D1B3E),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Historique', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: const Text('backup_20261002.zip'),
          subtitle: const Text('2 oct. 2026 - 15MB'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.restore), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
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
        const Text(
          'Correspondance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Poids des critères (Total: 100%)'),
        const SizedBox(height: 16),
        _buildSliderRow('Compétences', 40),
        _buildSliderRow('Localisation', 20),
        _buildSliderRow('Salaire', 10),
        _buildSliderRow('Expérience', 20),
        _buildSliderRow('Langues', 10),
        const SizedBox(height: 16),
        const Text("Seuil minimum d'affichage"),
        Slider(
          value: 50,
          min: 0,
          max: 100,
          divisions: 100,
          label: '50%',
          activeColor: const Color(0xFFF97316),
          onChanged: (v) {},
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Réinitialiser les poids'),
        ),
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
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Rappels de deadline'),
          subtitle: const Text("Notifier avant l'expiration"),
          value: true,
          onChanged: (v) {},
        ),
        DropdownButtonFormField<int>(
          value: 3,
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
          title: const Text('Alertes des veilles'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Sons'),
          value: false,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Notifications de bureau'),
          value: true,
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildNetworkSettings() {
    return ListView(
      children: [
        const Text(
          'Réseau',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Proxy', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Hôte',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 100,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                value: 'HTTP',
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
        const SizedBox(height: 24),
        const Text('Max requêtes simultanées'),
        Slider(
          value: 8,
          min: 1,
          max: 16,
          divisions: 15,
          label: '8',
          activeColor: const Color(0xFF22C55E),
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        const Text('Timeout (secondes)'),
        Slider(
          value: 30,
          min: 10,
          max: 120,
          divisions: 110,
          label: '30s',
          activeColor: const Color(0xFFF97316),
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        const TextField(
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
        const Text(
          'Intelligence Artificielle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un fournisseur IA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D1B3E),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OpenAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const Text('Modèle: gpt-4o-mini'),
                const Text('Clé API: sk-...abcd'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Tester la connexion'),
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
        const Text(
          'Sources',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_link),
          label: const Text('Ajouter une source personnalisée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Emploi.cm'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('LinkedIn Afrique'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('ReliefWeb'),
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
        const Text(
          "À propos d'OpportuNex",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Version: 1.0.0 (Production)'),
        const SizedBox(height: 8),
        const Text('Développé par: ING Momo Godi Yvan'),
        const SizedBox(height: 8),
        const Text('Financé par: Association PROTEGE QV'),
        const SizedBox(height: 8),
        const Text('Licence: GNU AGPL v3'),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.code),
          label: const Text('Code source sur GitHub'),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.history),
          label: const Text('Journal des modifications (Changelog)'),
        ),
      ],
    );
  }
}
