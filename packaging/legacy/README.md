# Anciens scripts de construction (obsolètes)

Ces scripts étaient à la racine du dépôt avant la finalisation. Ils sont **remplacés** et conservés seulement pour
l'historique : ils copiaient un environnement Python brut (`dist-venv`) au lieu d'un moteur PyInstaller, ne
produisaient ni installateur ni version portable, et leur paquet Debian n'avait pas les bonnes dépendances.

Utiliser à la place :

- Windows : `packaging/windows/build.ps1` (moteur PyInstaller, application Flutter, ZIP portable, installateur Inno
  Setup, `SHA256SUMS.txt`) ;
- Linux : `packaging/linux/build-deb.sh` dans l'image `packaging/linux/Dockerfile`, puis
  `packaging/linux/test-deb.sh`.

Ils peuvent être supprimés quand le propriétaire du dépôt le décide.
