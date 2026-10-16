# Guide utilisateur Opportunex

- `Guide_Utilisateur_Opportunex.docx` : guide utilisateur (français), version 1.0, pour Opportunex 1.0.0 — 19
  chapitres, 41 figures, environ 53 pages. Licence CC BY-SA 4.0.
- `screenshots/` : captures **réelles** utilisées par le guide.
- `tools/` : scripts qui produisent les captures, les vidéos et la version finale du document.

## D'où viennent les captures

| Fichiers | Origine |
| --- | --- |
| `install_*.png`, `app_01_first_launch.png` | Installateur réel `dist/windows/Opportunex-Setup-1.0.0-x64.exe` puis application installée, capturés fenêtre par fenêtre par `tools/capture_installer.ps1` (UI Automation + PrintWindow ; seul le contenu des fenêtres d'Opportunex est capturé). |
| toutes les autres | Test d'intégration `apps/desktop/integration_test/ui_tour_test.dart`, qui pilote l'application réelle et son moteur local sous Windows ; copiées depuis `apps/desktop/build/ui_tour/` par `build_guide.py`. |
| `ecran_principal_annote.png` | Capture du tableau de bord avec repères numérotés ajoutés par `build_guide.py`. |

Les personnes, établissements et offres visibles sont **fictifs** (site de démonstration local lancé par le test).
Les zones qui affichent un chemin contenant le nom d'utilisateur Windows sont pixelisées (`MASKS` dans
`build_guide.py`, et le dossier d'installation dans `capture_installer.ps1`).

## Régénérer le guide

```powershell
# 1. Captures de l'application (≈ 6 min, ouvre une fenêtre de test)
cd apps\desktop
flutter test integration_test\ui_tour_test.dart -d windows
cd ..\..
# 2. Captures de l'installateur (nécessite dist\windows, produit par packaging\windows\build.ps1 ;
#    Opportunex ne doit pas être déjà installé pour l'utilisateur courant)
powershell -ExecutionPolicy Bypass -File documentation\user-guide\tools\capture_installer.ps1
# 3. Document Word
engine\.venv\Scripts\python documentation\user-guide\build_guide.py
# 4. Table des matières et numéros de page (Microsoft Word requis ; sinon : clic droit sur la table > Mettre à jour)
powershell -ExecutionPolicy Bypass -File documentation\user-guide\tools\finalize_with_word.ps1
```

## Vidéos

Aucune vidéo n'a encore été enregistrée : l'outil `ffmpeg` n'est pas installé sur le poste de construction.
`tools/record_video.ps1` enregistre la fenêtre réelle d'Opportunex (lancée sur un dossier de données jetable) dans
`videos/<nom>.mp4` ; parcours prévus : installation, premier lancement, navigation, recherche, suivi d'une
candidature, sauvegarde et restauration.
