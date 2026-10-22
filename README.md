# BIIC CHAT

BIIC CHAT est une application Flutter de messagerie multiplateforme, conçue pour offrir une expérience simple, rapide et accessible sur Android, iOS et Web.

## Fonctionnalités

### Compte et sécurité
- inscription et connexion par téléphone/mot de passe, avec adresse e-mail de validation demandée à la création d’un compte par téléphone ;
- vérification du numéro par SMS ;
- récupération du mot de passe par SMS ;
- profil utilisateur créé automatiquement après inscription ;
- Row Level Security (RLS) sur les données privées ;
- conversations accessibles uniquement à leurs membres ;
- médias stockés dans des buckets privés ;
- aucune clé secrète de service Supabase dans l'application.

### Appels audio/vidéo — état actuel
- les boutons ouvrent une salle Jitsi dans un navigateur ou une application externe ;
- la discussion et les participants sont vérifiés avant l'ouverture ;
- les appels entrants avec sonnerie, acceptation/refus et média WebRTC intégré ne sont pas encore implémentés. Cette fonction ne doit donc pas être présentée comme un appel intégré complet.

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

**Attention : l'historique des migrations doit être réconcilié avant d'utiliser `supabase db push`.** Le dépôt contient plusieurs fichiers portant le même préfixe de version (`013`, `014`, `015` et `016`). Le CLI Supabase utilise ce préfixe comme version de migration ; ces doublons peuvent bloquer l'application automatisée ou provoquer un historique incohérent.

Fichiers actuellement présents :

- `001_initial_schema.sql`
- `002_members_auth_hardening.sql`
- `003_chat_media_storage.sql`
- `004_rls_realtime_fix.sql`
- `005_profiles_reports_safety.sql`
- `006_privacy_hardening.sql`
- `007_phone_accounts_and_deletion.sql`
- `008_imported_contacts.sql`
- `009_message_read_receipts.sql`
- `010_chat_reliability.sql`
- `011_scope_read_receipts.sql`
- `012_atomic_direct_conversations.sql`
- `013_normalize_ci_contact_phones.sql`
- `013_production_reliability.sql`
- `014_enforce_blocks_on_direct_chats.sql`
- `014_harden_rls_auto_enable.sql`
- `015_privacy_scope_block_checks.sql`
- `015_production_security_performance.sql`
- `016_fix_contact_hash_extension_search_path.sql`
- `016_harden_function_search_paths.sql`
- `017_rls_performance_and_block_privacy.sql`
- `20261021133331_block_aware_direct_conversations.sql`
- `20261021133449_bound_contact_sync_payload.sql`
- `20261021133521_protect_user_identity_columns.sql`
- `20261021133620_skip_invalid_contact_phones.sql`
- `20261021140000_email_verified_phone_registration.sql`
- `20261021140100_phone_directory_lookup.sql`
- `20261021141500_registration_email_for_phone_accounts.sql`

L'historique Supabase distant a été vérifié le 21 octobre 2026 et contient des migrations horodatées jusqu'à `20261021182947`. Les noms et versions historiques locaux ne correspondent pas exactement à cet historique, et plusieurs fichiers legacy partagent les préfixes `013`, `014`, `015` et `016`. Ne renommez pas les anciennes migrations et ne relancez pas leur SQL à l'aveugle sur la base de production : comparez d'abord chaque migration locale à l'historique distant, puis préparez une réconciliation non destructive avant d'utiliser `supabase db push`. Le détail des constats et actions est dans [`docs/PROJECT_HEALTH_AUDIT.md`](docs/PROJECT_HEALTH_AUDIT.md).

Le script `supabase/manual/BIIC_CHAT_REPAIR_013_016.sql` est un correctif manuel ciblé, pas un remplacement complet de toutes les migrations. Faites une sauvegarde et comparez son contenu à l'état réel de la base avant exécution. Après toute migration, vérifiez que Realtime est activé pour les tables utilisées et que les buckets `chat-media` et `avatars` restent privés.

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
