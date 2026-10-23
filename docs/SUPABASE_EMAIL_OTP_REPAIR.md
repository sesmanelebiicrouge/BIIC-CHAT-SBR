# BIIC CHAT — réparation de l'envoi des OTP e-mail

## Pourquoi Supabase refuse les e-mails

Le service e-mail intégré de Supabase est limité et, sans SMTP personnalisé, peut refuser l'envoi aux adresses qui ne font pas partie de l'équipe du projet. Pour un lancement public, BIIC CHAT doit utiliser un fournisseur d'e-mails transactionnels. Cette configuration ne peut pas être activée uniquement par un changement Flutter/GitHub : elle nécessite une clé fournisseur et l'activation du hook dans le tableau de bord Supabase.

## Solution préparée dans le dépôt

La fonction `supabase/functions/send-email/index.ts` reçoit le hook Send Email de Supabase Auth, vérifie sa signature Standard Webhooks, puis envoie le code OTP généré par Supabase via Resend. Supabase reste responsable de générer et valider le code : la fonction ne crée pas de codes elle-même et ne confirme pas les comptes sans validation.

## Préparation requise

1. Créer/ouvrir un compte Resend et vérifier un domaine d'envoi que vous contrôlez.
2. Créer une clé API Resend.
3. Déployer la fonction Edge `send-email`.
4. Ajouter les secrets suivants dans **Supabase → Edge Functions → Secrets** :
   - `RESEND_API_KEY` : clé API Resend (secret).
   - `BIIC_CHAT_FROM_EMAIL` : adresse expéditeur sur le domaine vérifié, par exemple `BIIC CHAT <auth@votre-domaine-verifie.ci>`.
   - `SEND_EMAIL_HOOK_SECRET` : secret de signature créé dans Supabase Auth Hooks. Conserver le format complet `v1,whsec_...`.
5. Dans **Supabase → Authentication → Hooks**, activer **Send Email** et sélectionner la fonction Edge `send-email`. Utiliser le même secret de signature que celui stocké dans `SEND_EMAIL_HOOK_SECRET`.
6. Vérifier que le fournisseur Email est activé dans **Authentication → Sign In / Providers**. Le hook ne peut pas envoyer d'e-mails si le fournisseur Email est désactivé.
7. Tester l'inscription, le renvoi du code et la récupération du mot de passe avec une adresse réelle. Vérifier les journaux de la fonction Edge et le journal e-mail de Resend.

## Important

- Ne jamais placer `RESEND_API_KEY`, `SEND_EMAIL_HOOK_SECRET`, une clé `service_role` ou tout autre secret dans Flutter, dans une variable compilée `--dart-define`, ni dans GitHub.
- Ne pas désactiver la confirmation d'e-mail comme contournement : cela laisserait des comptes non vérifiés accéder au service.
- Le domaine d'envoi doit être vérifié chez Resend. Une adresse expéditeur inventée ou non autorisée sera refusée.
- Si le projet utilise déjà un SMTP personnalisé fonctionnel, il est possible de corriger SMTP au lieu d'activer un hook. Ne pas activer plusieurs mécanismes d'envoi concurrents sans vérifier les paramètres Auth.
- Cette modification de dépôt ne suffit pas à activer la livraison en production. Il faut configurer les secrets et le hook dans le bon projet Supabase, puis tester un vrai e-mail.
