# Enregistrement du numéro par e-mail — BIIC CHAT

## Fonctionnement
Un utilisateur connecté saisit le numéro à associer à son compte. Pour les nouveaux comptes créés par téléphone, l’adresse e-mail est enregistrée au moment de l’inscription dans le profil privé. Le serveur utilise cette adresse (ou l’adresse Supabase Auth pour les comptes e-mail existants), envoie un code à 6 chiffres, puis n’active la visibilité du numéro qu’après validation. Le code expire au bout de 10 minutes; les demandes sont limitées à une par minute et les essais à cinq.

Lors de la création d’un compte par téléphone, l’adresse e-mail de validation est demandée et enregistrée dans le profil privé. Les anciens comptes sans e-mail peuvent en saisir un dans le parcours d’enregistrement du numéro; cette adresse n’est enregistrée qu’après validation du code reçu. Le code est lié au compte, au numéro et à l’adresse e-mail, expire après 10 minutes, et les tentatives sont limitées.

Le répertoire public et la synchronisation des contacts ne reconnaissent que les numéros ayant `phone_verified_at` et `registered_phone` renseignés. Une recherche exacte par numéro utilise la fonction `find_user_by_registered_phone`.

## Déploiement requis
1. Appliquer les migrations `20261021140000_email_verified_phone_registration.sql`, `20261021140100_phone_directory_lookup.sql` et `20261021141500_registration_email_for_phone_accounts.sql` au projet Supabase. Réconcilier d’abord l’historique des migrations numérotées dupliquées et sauvegarder la base.
2. Déployer l'Edge Function `phone-registration` avec la vérification JWT activée.
3. Configurer les secrets `RESEND_API_KEY` et `PHONE_OTP_FROM_EMAIL`. L'expéditeur doit appartenir à un domaine vérifié dans Resend. L'environnement Supabase fournit `SUPABASE_URL`, `SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY`; ne jamais exposer la clé service-role dans Flutter.
4. Tester avec deux comptes : un numéro non validé ne doit pas apparaître; après saisie du code reçu sur l'e-mail du compte, la recherche et la synchronisation de contacts doivent retrouver ce compte.

## Limite avant mise en production
Le code et les migrations sont ajoutés au dépôt. L'envoi réel des e-mails nécessite encore la configuration de Resend et le déploiement de la fonction sur Supabase. Les numéros historiques ne deviennent pas automatiquement validés : chaque utilisateur doit suivre ce processus.
