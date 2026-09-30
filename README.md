# BIIC CHAT

BIIC CHAT est une application Flutter de messagerie multiplateforme, conçue pour offrir une expérience simple, rapide et accessible sur Android, iOS et Web.

## Fonctionnalités

### Compte et sécurité
- inscription et connexion par e-mail/mot de passe ;
- récupération du mot de passe ;
- profil utilisateur créé automatiquement après inscription ;
- Row Level Security (RLS) sur les données privées ;
- conversations accessibles uniquement à leurs membres ;
- médias stockés dans un bucket privé ;
- aucune clé de service Supabase dans l'application.

### Messagerie
- liste des conversations ;
- recherche de membres ;
- création automatique d'une conversation privée ;
- messages persistants dans Supabase ;
- réception temps réel via Supabase Realtime ;
- horodatage côté serveur ;
- pièces jointes prévues via stockage privé ;
- partage de contacts, images, photos et fichiers côté appareil.

### Accessibilité et expérience
- interface Material 3 ;
- navigation simple ;
- états de chargement et erreurs ;
- recherche de membres ;
- fonctionnement dégradé sans configuration backend pour le mode démo ;
- préparation Android, iOS et Web.

## Architecture

- Flutter / Dart
- Supabase Auth
- Supabase Postgres
- Supabase Realtime
- Supabase Storage
- Material 3
- file_picker
- image_picker
- flutter_contacts
- url_launcher

## Configuration Supabase

Ne committez jamais une clé secrète de service.

Utilisez une clé publique côté client :

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

L'ancien nom `SUPABASE_ANON_KEY` reste accepté pour compatibilité.

Appliquer les migrations dans l'ordre :
1. `001_initial_schema.sql`
2. `002_members_auth_hardening.sql`
3. `003_chat_media_storage.sql`
4. `004_rls_realtime_fix.sql`

Après migration, vérifier dans Supabase que Realtime est activé et que le bucket `chat-media` reste privé.

## Développement

```bash
flutter pub get
flutter create .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

Le dépôt ne contient pas encore les plateformes natives générées. Le workflow CI génère Android et Web pour validation. Pour iOS, générer la plateforme sur macOS avec Xcode avant une distribution App Store.

## CI

GitHub Actions exécute l'installation des dépendances, le formatage, l'analyse, les tests et le build Web. Les plateformes Android/Web manquantes sont générées pendant la CI afin de détecter les erreurs de compilation.

## Avant publication

- définir l'identifiant d'application Android et le bundle identifier iOS ;
- configurer les icônes, le nom de l'application et les écrans de lancement ;
- générer et tester les plateformes natives ;
- configurer les permissions Android/iOS uniquement pour les fonctions réellement utilisées ;
- configurer la signature Android et iOS ;
- ajouter les notifications push ;
- ajouter la politique de confidentialité et les conditions d'utilisation ;
- tester inscription, récupération de compte, messagerie, médias, réseau lent/hors ligne et suppression de compte ;
- effectuer des tests sur plusieurs tailles d'écran et appareils réels ;
- vérifier les exigences actuelles de Google Play et App Store Connect avant chaque soumission.

## État

Le projet dispose maintenant d'une base backend réelle pour les comptes, profils, membres, conversations privées, messages temps réel et stockage média privé. Les tests sur appareils réels, la configuration des comptes de publication et certaines intégrations natives de distribution restent nécessaires avant une publication publique.
