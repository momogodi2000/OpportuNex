import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(onPressed: () {}, child: Text('Enregistrer et quitter')),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index <= _currentStep
                  ? const Color(0xFF22C55E)
                  : Colors.grey[300],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      case 5:
        return _buildStep6();
      case 6:
        return _buildStep7();
      default:
        return SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenue ! Qui êtes-vous ?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Nom de profil',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 24),
        Text('Statut actuel', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'Étudiant',
                    'Professionnel',
                    'Freelance',
                    'ONG',
                    'Entrepreneur',
                    'Autre',
                  ]
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e),
                      selected: e == 'Professionnel',
                      onSelected: (_) {},
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Où êtes-vous basé ?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Pays',
            border: OutlineInputBorder(),
          ),
          items: [
            'Sénégal',
            "Côte d'Ivoire",
            'Cameroun',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Mode de travail souhaité',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Sur site', 'Hybride', 'Télétravail']
              .map(
                (e) => ChoiceChip(
                  label: Text(e),
                  selected: e == 'Hybride',
                  onSelected: (_) {},
                ),
              )
              .toList(),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text('Prêt à déménager ?'),
          value: true,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre formation',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: "Niveau d'études",
            border: OutlineInputBorder(),
          ),
          items: [
            'Licence',
            'Master',
            'Doctorat',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (_) {},
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: "Domaine d'études",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: "Année d'obtention",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Établissement',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expérience professionnelle',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Titre du poste',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Employeur',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: "Années d'expérience",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: Text("C'est mon poste actuel"),
          value: true,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos compétences',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Rechercher une compétence...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text('Gestion de projet'), onDeleted: () {}),
            Chip(label: Text('Analyse de données'), onDeleted: () {}),
          ],
        ),
        SizedBox(height: 24),
        Text('Niveau pour "Gestion de projet"'),
        Slider(
          value: 2,
          min: 0,
          max: 3,
          divisions: 3,
          label: 'Intermédiaire',
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langues',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Langue',
                  border: OutlineInputBorder(),
                ),
                items: ['Français', 'Anglais', 'Espagnol']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Niveau CECRL',
                  border: OutlineInputBorder(),
                ),
                items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(Icons.add),
          label: Text('Ajouter une langue'),
        ),
      ],
    );
  }

  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quels sont vos objectifs ?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 32),
        CheckboxListTile(
          title: Text("Bourses d'études"),
          value: true,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: Text("Offres d'emploi"),
          value: true,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: Text("Appels d'offres"),
          value: false,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: Text('Entrepreneuriat (Financement)'),
          value: false,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: Text('Recherche'),
          value: false,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: Text('Volontariat'),
          value: false,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: Text('Précédent'),
            )
          else
            TextButton(onPressed: () {}, child: Text('Passer')),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              if (_currentStep < _totalSteps - 1) {
                setState(() => _currentStep++);
              } else {
                // Navigate to dashboard
              }
            },
            child: Text(
              _currentStep < _totalSteps - 1 ? 'Suivant' : 'Terminer',
            ),
          ),
        ],
      ),
    );
  }
}
