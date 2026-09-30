# BIIC CHAT — checklist de mise en production

## Déjà intégré
- Authentification Supabase : inscription, connexion, déconnexion et récupération du mot de passe.
- Conversations privées et groupes.
- Messages temps réel via Supabase Realtime.
- Pièces jointes privées : images et fichiers jusqu'à 20 Mo côté client.
- Profils : nom, bio, statut et avatar privé.
- Blocage et signalement d'utilisateurs.
- RLS Supabase et vérification d'appartenance aux conversations.
- Protection contre l'envoi de messages avec un utilisateur bloqué.
- CI GitHub Actions : analyse, formatage, tests et build Web.
- Tests automatisés de la configuration publique Supabase.

## À configurer avant publication
1. Appliquer les migrations Supabase dans l'ordre, jusqu'à 007_phone_accounts_and_deletion.sql.
2. Renseigner SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY comme variables de build.
3. Ne jamais mettre la clé service_role dans Flutter.
4. Configurer les notifications push Android/iOS/Web avec Firebase/FCM et les credentials de production.
5. Configurer la suppression de compte côté serveur avant d'activer cette action dans l'application.
6. Créer les identifiants de signature Android et iOS et conserver les secrets hors du dépôt. La clé d'upload Android doit rester sauvegardée hors GitHub.
7. Définir le package Android et le bundle ID iOS définitifs.
8. Vérifier les permissions caméra, galerie, fichiers et notifications sur chaque plateforme.
9. Vérifier et valider juridiquement la politique de confidentialité et les conditions d'utilisation accessibles via /privacy.html et /terms.html.
10. Faire un test réel sur plusieurs téléphones Android, puis sur iOS et Web, notamment sur réseau mobile lent et en arrière-plan.
11. Vérifier sauvegardes, logs, quotas, alertes et règles anti-abus Supabase.
12. Préparer captures d'écran, icônes, description, URL de confidentialité et formulaire de confidentialité des stores.

## Sécurité
- Les buckets chat-media et avatars restent privés.
- Les fichiers sont servis avec des URLs signées temporaires.
- Les accès aux conversations et messages passent par RLS.
- Les actions de blocage sont liées au compte connecté.
- Les signalements sont enregistrés côté serveur.
- Les messages exigent du texte ou une pièce jointe.
- Les fichiers envoyés depuis l'application sont limités à 20 Mo.

## À vérifier avant de déclarer la production prête
- Exécuter la migration 007 dans le projet Supabase de production.
- Vérifier que l'inscription avec deux numéros différents fonctionne et que le changement de numéro synchronise le profil.
- Tester la suppression de compte sur un compte de test et confirmer la suppression des données associées.
- Vérifier que les notifications push sont configurées avant de promettre des notifications en arrière-plan.

## Limite
La configuration des notifications push, de la signature des applications et des comptes de publication nécessite les credentials du propriétaire du projet. Ces secrets ne doivent pas être inventés ni commités dans Git.