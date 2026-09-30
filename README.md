# BIIC CHAT

BIIC CHAT est une application Flutter de messagerie multiplateforme, conçue pour offrir une expérience simple, rapide et accessible sur Android, iOS et Web.

## Fonctionnalités

### Compte et sécurité
- inscription et connexion par téléphone/mot de passe ;
- vérification du numéro par SMS ;
- récupération du mot de passe par SMS ;
- profil utilisateur créé automatiquement après inscription ;
- Row Level Security (RLS) sur les données privées ;
- conversations accessibles uniquement à leurs membres ;
- médias stockés dans un bucket privé ;
- aucune clé de service Supabase dans l'application.

### Messagerie
- liste des conversations ;
- recherche de membres ;
- création de conversations privées ;
- messages persistants dans Supabase ;
- réception temps réel via Supabase Realtime ;
- pièces jointes : images, photos, fichiers et contacts.

### Accessibilité et expérience
- interface Material 3 ;
- navigation simple ;
- états de chargement et erreurs ;
- mode démo sans backend configuré ;
- préparation Android, iOS et Web.

## Architecture

- Flutter / Dart
- Supabase Auth
- Supabase Postgres
- Supabase Realtime
- Supabase Storage
- Material 3

## Configuration Supabase

Ne committez jamais une clé secrète de service.

Utilisez une clé publique côté client :

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

L'ancien nom `SUPABASE_ANON_KEY` reste accepté pour compatibilité.

## Migrations Supabase

Appliquer dans l'ordre :
1. `001_initial_schema.sql`
2. `002_members_auth_hardening.sql`
3. `003_chat_media_storage.sql`
4. `004_rls_realtime_fix.sql`
5. `005_profiles_reports_safety.sql`
6. `006_privacy_hardening.sql`
7. `007_phone_accounts_and_deletion.sql`
8. `008_imported_contacts.sql`
9. `009_message_read_receipts.sql`
10. `010_chat_reliability.sql`
11. `011_scope_read_receipts.sql`
12. `012_atomic_direct_conversations.sql`

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

## Publication Web

Chaque modification poussée sur `main` déclenche la construction et la publication Web via GitHub Actions sur la branche `gh-pages`.

## État

La version Web doit être vérifiée après chaque déploiement sur :
https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/
