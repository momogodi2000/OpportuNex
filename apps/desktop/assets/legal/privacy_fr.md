# Politique de confidentialité d'Opportunex

Version 1.0 — 15 octobre 2026

## 1. Principe : vos données restent chez vous
Opportunex fonctionne en local. Votre profil, vos recherches, vos opportunités sauvegardées, vos candidatures et vos documents sont enregistrés sur votre ordinateur, dans une base chiffrée (SQLCipher, AES-256). La clé de cette base est protégée par votre mot de passe. L'éditeur n'a accès à aucune de ces données.

## 2. Données enregistrées localement
- Compte : nom affiché, adresse électronique, empreinte du mot de passe (Argon2id).
- Profil : formation, expériences, compétences, langues, objectifs et préférences que vous saisissez.
- Activité : recherches, résultats, sauvegardes, statuts de candidature, notes, rappels.
- Documents joints : conservés chiffrés dans un coffre local.
- Journaux techniques : expurgés automatiquement (aucun courriel, jeton ni clé).

## 3. Ce qui quitte votre ordinateur
- Consultation des sources : Opportunex télécharge des pages publiques sur les sites des éditeurs d'opportunités. Ces requêtes ne contiennent aucune donnée de votre profil.
- Intelligence artificielle (désactivée par défaut) : si vous configurez un fournisseur d'IA distant, Opportunex vous demande d'abord votre consentement explicite. Il n'envoie qu'un profil anonymisé (sans nom, contact ni identifiant) et consigne chaque envoi dans votre tableau de bord de confidentialité. Les clés d'API sont conservées dans le trousseau de votre système, jamais dans la base.
- Synchronisation (facultative) : si vous l'activez, vos données sont chiffrées de bout en bout avant l'envoi ; le serveur ne peut pas les lire.

## 4. Aucune télémétrie
Opportunex ne collecte aucune statistique d'utilisation et n'envoie aucun rapport d'erreur automatiquement.

## 5. Vos droits et vos réglages
Depuis l'application, vous pouvez à tout moment :
- consulter les données stockées et les envois effectués ;
- retirer un consentement ;
- exporter l'intégralité de vos données ;
- effacer sélectivement l'historique, les documents ou les opportunités ;
- supprimer définitivement votre compte.

## 6. Sauvegardes
Les sauvegardes sont chiffrées avec la même clé que votre base. Conservez-les en lieu sûr : elles ne peuvent être restaurées qu'avec votre mot de passe.

## 7. Contact
Pour toute question ou demande : https://github.com/momogodi2000/OpportuNex/issues
