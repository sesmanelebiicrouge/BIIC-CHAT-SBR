# BIIC CHAT — réparation de l'envoi des OTP e-mail

## Diagnostic

Le service e-mail intégré de Supabase peut limiter les envois publics lorsque le projet n'utilise pas un SMTP personnalisé. La solution préparée utilise le hook **Authentication → Hooks → Send Email** et Resend. Cette configuration ne peut pas être activée uniquement par un changement Flutter/GitHub : elle nécessite une clé fournisseur, un domaine d'envoi vérifié et l'activation du hook dans le tableau de bord Supabase.

## Ce que fait la fonction

La fonction `supabase/functions/send-email/index.ts` :

- vérifie la signature Standard Webhooks avant de faire confiance au payload ;
- envoie les codes OTP générés et validés par Supabase, sans générer de codes elle-même ;
- gère l'inscription, la récupération du mot de passe, la connexion par code, les invitations et la réauthentification ;
- gère le changement d'adresse e-mail sécurisé : si Supabase fournit deux codes, un e-mail est envoyé à l'adresse actuelle et un autre à la nouvelle adresse ; si un seul code est fourni, il est envoyé à la nouvelle adresse ;
- transmet les notifications de sécurité de changement de mot de passe, d'adresse e-mail, de téléphone, de méthode de connexion et de facteur MFA ;
- renvoie une erreur au hook si Resend refuse le message, afin que l'échec ne soit pas présenté comme une livraison réussie.

Supabase reste responsable de générer et valider les codes. La fonction ne confirme pas les comptes sans validation.

## Préparation requise

1. Ouvrir le compte Resend et vérifier un domaine d'envoi que vous contrôlez.
2. Créer une clé API Resend. Ne la coller ni dans le dépôt, ni dans Flutter, ni dans une conversation.
3. Déployer la fonction Edge `send-email` dans le **bon projet Supabase**.
4. Ajouter les secrets dans **Supabase → Edge Functions → Secrets** :
   - `RESEND_API_KEY` : clé API Resend ;
   - `BIIC_CHAT_FROM_EMAIL` : adresse expéditeur sur le domaine vérifié, par exemple `BIIC CHAT <auth@votre-domaine-verifie.ci>` ;
   - `SEND_EMAIL_HOOK_SECRET` : secret complet généré dans Supabase Auth Hooks, au format fourni par Supabase.
5. Dans **Supabase → Authentication → Hooks**, activer **Send Email**, sélectionner la fonction Edge `send-email` et utiliser le même secret de signature que dans `SEND_EMAIL_HOOK_SECRET`.
6. Vérifier que le fournisseur Email est activé dans **Authentication → Sign In / Providers**. Si le fournisseur Email est désactivé, l'inscription par e-mail sera désactivée même si le hook est configuré.
7. Tester avec une vraie adresse e-mail : inscription, renvoi du code, récupération du mot de passe et, si utilisé, changement d'adresse. Vérifier les journaux Edge Functions et le journal d'envoi Resend.

## Sécurité et limites

- Ne jamais placer `RESEND_API_KEY`, `SEND_EMAIL_HOOK_SECRET`, une clé `service_role` ou tout autre secret dans Flutter, une variable compilée `--dart-define`, ou un fichier Git.
- Ne pas désactiver la confirmation d'e-mail pour contourner le problème.
- Le domaine d'envoi doit être vérifié chez Resend. Une adresse expéditeur non autorisée sera refusée.
- Ne pas activer plusieurs mécanismes d'envoi concurrents sans vérifier la configuration Auth existante.
- Le changement de code dans GitHub ne suffit pas à activer la livraison en production. Les secrets, le hook et le test réel restent nécessaires.
- Le projet Supabase doit être accessible avant tout déploiement ou changement de configuration en production.
