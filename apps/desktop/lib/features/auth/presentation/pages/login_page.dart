import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      next.whenData((state) {
        state.maybeWhen(
          authenticated: (_, __) {
            context.go('/dashboard');
          },
          orElse: () {},
        );
      });
    });

    final isLoading = authState.maybeWhen(
      data: (state) =>
          state.maybeWhen(loading: () => true, orElse: () => false),
      loading: () => true,
      orElse: () => false,
    );

    final errorMsg = authState.maybeWhen(
      data: (state) => state.maybeWhen(error: (msg) => msg, orElse: () => null),
      orElse: () => null,
    );

    return Scaffold(
      body: Row(
        children: [
          // Left branded panel on wide screens
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              child: Container(
                color: AppTheme.primaryNavy,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLogo(fontSize: 48, darkBackground: true),
                      SizedBox(height: 16),
                      Text(
                        'Trouvez · Analysez · Réalisez',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Login Form
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (MediaQuery.of(context).size.width <= 800) ...[
                        const Center(child: AppLogo(fontSize: 40)),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Trouvez · Analysez · Réalisez',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Text(
                        'Connexion',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.red.withOpacity(0.1),
                          child: Text(
                            errorMsg,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) => v!.isEmpty
                            ? 'Veuillez entrer votre mot de passe'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Créer un compte'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/recover'),
                            child: const Text('Récupérer mon compte'),
                          ),
                        ],
                      ),
                      const Divider(height: 48),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/local-profiles'),
                        icon: const Icon(Icons.folder_shared),
                        label: const Text('Profils locaux'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
