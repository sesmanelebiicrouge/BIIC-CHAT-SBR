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
- médias stockés dans des buckets privés ;
- aucune clé secrète de service Supabase dans l'application.

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
- préparation Android, iOS et Web.

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

Appliquer dans l'ordre, une seule fois, les migrations du dossier supabase/migrations, par numéro croissant :
1. 001_initial_schema.sql
2. 002_members_auth_hardening.sql
3. 003_chat_media_storage.sql
4. 004_rls_realtime_fix.sql
5. 005_profiles_reports_safety.sql
6. 006_privacy_hardening.sql
7. 007_phone_accounts_and_deletion.sql
8. 008_imported_contacts.sql
9. 009_message_read_receipts.sql
10. 010_chat_reliability.sql
11. 011_scope_read_receipts.sql
12. 012_atomic_direct_conversations.sql
13. 013_normalize_ci_contact_phones.sql
14. 014_enforce_blocks_on_direct_chats.sql

Après migration, vérifier dans Supabase que Realtime est activé pour les tables utilisées, et que les buckets chat-media et avatars restent privés.

## SMS OTP Orange Côte d'Ivoire

La fonction supabase/functions/send-sms/index.ts doit être déployée séparément dans Supabase Edge Functions. La publication GitHub Pages du site ne déploie pas cette fonction et n'applique pas les migrations SQL.

Configurer uniquement dans les secrets de la fonction Supabase :
- ORANGE_SMS_CLIENT_ID
- ORANGE_SMS_CLIENT_SECRET
- ORANGE_SMS_SENDER
- SEND_SMS_HOOK_SECRET
- ORANGE_SMS_SENDER_NAME seulement si Orange a approuvé ce nom.

Dans Supabase Auth, activer le hook Send SMS et utiliser le même secret de signature que celui configuré pour la fonction. Vérifier les journaux Supabase et l'accès Orange (API SMS Côte d'Ivoire, autorisation du sender et crédits SMS) si l'envoi échoue. Ne jamais mettre ces secrets dans le code client, dans GitHub ou dans une conversation.

## Développement

    flutter pub get
    flutter create --platforms=web --org com.biicchat --project-name biic_chat_sbr .
    dart format --output=none --set-exit-if-changed .
    flutter analyze
    flutter test
    flutter build web --release

## Publication Web

Le workflow .github/workflows/deploy.yml reconstruit l'application web lors d'un push sur main, puis publie le résultat sur la branche gh-pages. Il injecte l'URL Supabase et la clé publique de compilation depuis le workflow. Un déploiement Web réussi ne garantit pas que les secrets Orange, le hook SMS ou les migrations Supabase sont correctement configurés.

URL publique :
https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/
