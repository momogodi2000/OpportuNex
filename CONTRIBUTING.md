# Contribuer à Opportunex / Contributing

Merci de votre intérêt ! *Thank you for your interest!* The English version follows the French one.

## En français

### Avant de commencer
- Ouvrez d'abord un ticket pour toute modification importante, afin d'en discuter.
- Le cahier des charges (`documentation/cahier_de_charge/`) et le registre des décisions
  (`documentation/DECISIONS.md`) font référence. Une proposition qui s'en écarte doit le dire.
- Aucune donnée fictive dans le code livré ; aucun secret (clé, jeton, mot de passe) dans le dépôt.

### Environnement de développement
```powershell
.\launch-dev.ps1 -Setup     # crée engine/.venv et installe les dépendances
.\launch-dev.ps1 -Checks    # ruff, mypy, pytest, flutter analyze, flutter test
.\launch-dev.ps1            # lance le moteur et l'application en mode développement
```

### Règles de qualité
- Moteur : `ruff check`, `ruff format`, `mypy`, `pytest` sans échec ; tout correctif est accompagné d'un test.
- Application : `flutter analyze` sans remarque, `flutter test` ; toute chaîne visible est traduite (ARB FR et EN).
- Les tests existants ne sont ni supprimés ni affaiblis.
- Messages de commit courts, à l'impératif, en anglais.

### Certificat d'origine (DCO) et licence des contributions
Chaque commit doit porter la ligne :

```
Signed-off-by: Prénom Nom <adresse@example.org>
```

(`git commit -s`). En l'ajoutant, vous certifiez le **Developer Certificate of Origin 1.1**
(https://developercertificate.org/) : vous avez le droit de soumettre cette contribution sous la
licence du projet.

**Licence entrante.** En plus de la licence GNU AGPL v3, vous accordez à ETS Monthe Network et à
Momo Godi Yvan une licence non exclusive, mondiale, perpétuelle, gratuite et irrévocable
d'utiliser, reproduire, modifier et distribuer votre contribution, y compris sous d'autres
conditions de licence (par exemple une licence commerciale proposée en parallèle de l'AGPL).
Vous conservez vos droits d'auteur. Cette clause permet une double licence future (décision D-03).
*Cette clause est en attente de relecture juridique (voir `documentation/LEGAL_DECISIONS_NEEDED.md`).*

### Connecteurs de sources
Les connecteurs déclaratifs (`engine/connectors/`) sont sous Apache 2.0. Une source n'est
activée par défaut que si ses conditions d'utilisation et son robots.txt l'autorisent ; sinon elle
est proposée comme lien officiel.

## In English

- Open an issue first for significant changes. The specification and `documentation/DECISIONS.md` are the reference.
- No fake data in shipped code; no secrets in the repository.
- Engine: `ruff`, `mypy` and `pytest` must pass and every fix comes with a test. Desktop: `flutter analyze` must be
  clean, `flutter test` must pass, and every visible string must be translated (FR and EN ARB files). Existing tests
  are never removed or weakened.
- Sign off every commit (`git commit -s`), which certifies the **Developer Certificate of Origin 1.1**.
- **Inbound licence:** in addition to the GNU AGPL v3, you grant ETS Monthe Network and Momo Godi Yvan a
  non-exclusive, worldwide, perpetual, royalty-free and irrevocable licence to use, reproduce, modify and distribute
  your contribution, including under other licence terms (for example a commercial licence offered alongside the AGPL).
  You keep your copyright. *This clause is awaiting legal review.*
