# BIIC CHAT

BIIC CHAT est une application Flutter de messagerie multiplateforme, conçue pour offrir une expérience simple, rapide et accessible sur Android, iOS et Web.

## Fonctionnalités

### Compte et sécurité
- inscription et connexion par téléphone/mot de passe ;
- vérification du numéro par SMS ;
- parcours prévu de validation du numéro BIIC CHAT par code envoyé à l’e-mail du compte (voir les prérequis dans `docs/PHONE_REGISTRATION_EMAIL_OTP.md`) ;
- récupération du mot de passe par SMS ;
- profil utilisateur créé automatiquement après inscription ;
- Row Level Security (RLS) sur les données privées ;
- conversations accessibles uniquement à leurs membres ;
- médias stockés dans des buckets privés ;
- aucune clé secrète de service Supabase dans l'application.

### Messagerie
- liste des conversations, discussions privées et groupes ;
- recherche des membres et correspondance des contacts de l’appareil ;
- messages persistants dans Supabase et réception temps réel via Supabase Realtime ;
- accusés de lecture ;
- pièces jointes : images, photos, vidéos, fichiers et contacts ;
- partage volontaire de la position courante sous forme de lien Google Maps ;
- appels audio/vidéo lancés dans un service externe.

### Confidentialité et expérience
- permissions demandées au moment où une fonctionnalité est utilisée ;
- sélecteurs système pour choisir photos, vidéos et documents, sans accès global au stockage ;
- blocage et signalement d’utilisateurs ;
- profil, suppression du compte et configuration de la double authentification ;
- interface Material 3 et états de chargement/erreur.

## Architecture
- Flutter / Dart
- Supabase Auth
- Supabase Postgres
- Supabase Realtime
- Supabase Storage
- Material 3

## Configuration Supabase

Ne committez jamais une clé secrète de service ou les identifiants Orange.

Le client Flutter utilise une clé publique Supabase via les options de compilation SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY. Une clé publique/publishable peut être incluse dans le client, à condition que les tables et fonctions soient correctement protégées par RLS et les contrôles serveur. N'utilisez jamais une clé service_role ou une clé secrète Supabase dans l'application.

## Migrations Supabase

**Attention : l'historique des migrations doit être réconcilié avant d'utiliser `supabase db push`.** Le dépôt contient plusieurs fichiers portant le même préfixe de version (`013`, `014`, `015` et `016`). Le CLI Supabase utilise ce préfixe comme version de migration ; ces doublons peuvent bloquer l'application automatisée ou provoquer un historique incohérent.

Les migrations de validation e-mail/téléphone ajoutées sur la branche de fonctionnalité doivent être examinées et appliquées après vérification de l’historique réel de la base. Ne renommez pas les anciennes migrations et ne relancez pas leurs SQL à l’aveugle sur la production. Faites une sauvegarde, réconciliez l’historique distant et vérifiez RLS, Realtime ainsi que les buckets privés `chat-media` et `avatars`.

## SMS OTP Orange Côte d'Ivoire

La fonction `supabase/functions/send-sms/index.ts` doit être déployée séparément dans Supabase Edge Functions. La publication GitHub Pages du site ne déploie pas cette fonction et n'applique pas les migrations SQL.

Configurer uniquement dans les secrets de la fonction Supabase :
- `ORANGE_SMS_CLIENT_ID`
- `ORANGE_SMS_CLIENT_SECRET`
- `ORANGE_SMS_SENDER`
- `SEND_SMS_HOOK_SECRET`
- `ORANGE_SMS_SENDER_NAME` seulement si Orange a approuvé ce nom.

Dans Supabase Auth, activer le hook Send SMS et utiliser le même secret de signature que celui configuré pour la fonction. Vérifier les journaux Supabase et l'accès Orange (API SMS Côte d'Ivoire, autorisation du sender et crédits SMS) si l'envoi échoue. Ne jamais mettre ces secrets dans le code client, dans GitHub ou dans une conversation.

## Développement

    flutter pub get
    flutter create --platforms=web --org com.biicchat --project-name biic_chat_sbr .
    dart format --output=none --set-exit-if-changed .
    flutter analyze
    flutter test
    flutter build web --release

## Publication Web

Le workflow `.github/workflows/deploy.yml` reconstruit l'application web lors d'un push sur `main`, puis publie le résultat sur la branche `gh-pages`. Il injecte l'URL Supabase et la clé publique de compilation depuis le workflow. Un déploiement Web réussi ne garantit pas que les secrets Orange, le hook SMS ou les migrations Supabase sont correctement configurés.

URL publique :
https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/
