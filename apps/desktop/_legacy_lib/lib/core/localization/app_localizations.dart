import 'package:flutter/material.dart';

class AppLoc {
  static AppLoc of(BuildContext context) {
    return Localizations.of<AppLoc>(context, AppLoc) ??
        AppLoc(const Locale('fr', 'FR'));
  }

  final Locale locale;
  AppLoc(this.locale);

  static const LocalizationsDelegate<AppLoc> delegate = _AppLocDelegate();

  bool get isEn => locale.languageCode == 'en';

  String get(String key) {
    if (isEn) {
      return _en[key] ?? key;
    }
    return _fr[key] ?? key;
  }

  static const Map<String, String> _fr = {
    'login': 'Connexion',
    'create_account': 'Créer un compte',
    'email': 'Adresse e-mail',
    'password': 'Mot de passe',
    'dashboard': 'Tableau de bord',
    'search': 'Recherche',
    'opportunities': 'Opportunités',
    'monitors': 'Surveillances',
    'applications': 'Candidatures',
    'settings': 'Paramètres',
    'account': 'Compte',
    'appearance': 'Apparence',
    'privacy': 'Confidentialité',
    'backups': 'Sauvegardes',
    'matching': 'Correspondance',
    'notifications': 'Notifications',
    'network': 'Réseau',
    'about': 'À propos',
    'theme': 'Thème',
    'light': 'Clair',
    'dark': 'Sombre',
    'system': 'Système',
    'language': 'Langue',
    // ... we will expand this
  };

  static const Map<String, String> _en = {
    'login': 'Login',
    'create_account': 'Create an account',
    'email': 'Email Address',
    'password': 'Password',
    'dashboard': 'Dashboard',
    'search': 'Search',
    'opportunities': 'Opportunities',
    'monitors': 'Monitors',
    'applications': 'Applications',
    'settings': 'Settings',
    'account': 'Account',
    'appearance': 'Appearance',
    'privacy': 'Privacy',
    'backups': 'Backups',
    'matching': 'Matching',
    'notifications': 'Notifications',
    'network': 'Network',
    'about': 'About',
    'theme': 'Theme',
    'light': 'Light',
    'dark': 'Dark',
    'system': 'System',
    'language': 'Language',
    // ...
  };
}

class _AppLocDelegate extends LocalizationsDelegate<AppLoc> {
  const _AppLocDelegate();
  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);
  @override
  Future<AppLoc> load(Locale locale) async => AppLoc(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLoc> old) => false;
}
