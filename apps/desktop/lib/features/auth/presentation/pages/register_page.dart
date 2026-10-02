import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  double _passwordStrength = 0;
  List<String>? _recoveryPhrase;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _calculateStrength(String value) {
    double strength = 0;
    if (value.length >= 12) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]')))
      strength += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (value.contains(RegExp(r'[!@#\$&*~]'))) strength += 0.25;
    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength <= 0.25) return Colors.red;
    if (_passwordStrength <= 0.5) return Colors.orange;
    if (_passwordStrength <= 0.75) return Colors.amber;
    return Colors.green;
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _passwordStrength == 1.0) {
      // In a real implementation, we would call the repository here.
      // Simulating a successful registration returning a 12-word phrase:
      setState(() {
        _recoveryPhrase = [
          'apple',
          'mountain',
          'river',
          'stone',
          'eagle',
          'cloud',
          'forest',
          'valley',
          'ocean',
          'stars',
          'moon',
          'sun',
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recoveryPhrase != null) {
      return _buildRecoveryPhraseView();
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Créer un compte',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Veuillez entrer votre nom' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Veuillez entrer votre email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: _calculateStrength,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Veuillez entrer un mot de passe';
                      if (_passwordStrength < 1.0)
                        return 'Mot de passe trop faible';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey.shade300,
                    color: _getStrengthColor(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Doit contenir 12+ caractères, majuscules, minuscules, chiffres, et symboles.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text)
                        return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _passwordStrength == 1.0 ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Retour à la connexion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryPhraseView() {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: AppTheme.primaryNavy),
              const SizedBox(height: 24),
              Text(
                'Phrase de récupération',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Conservez ces 12 mots en lieu sûr. Ils sont le seul moyen de récupérer votre compte en cas de perte de mot de passe.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recoveryPhrase!.asMap().entries.map((e) {
                    return Chip(
                      label: Text('${e.key + 1}. ${e.value}'),
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _recoveryPhrase!.join(' ')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phrase copiée dans le presse-papiers'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copier la phrase'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                ),
                child: const Text("J'ai noté ma phrase"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
