# Feuille de route BIIC CHAT SBR

Ce document sépare ce qui existe dans le code des fonctionnalités qui demandent encore une implémentation ou une configuration de production. Une autorisation système déclarée n'est pas une fonctionnalité livrée.

## Déjà présentes dans le dépôt (à revalider par tests)

- Authentification Supabase par téléphone/SMS et profil utilisateur.
- Conversations privées et groupes, messages temps réel et accusés de lecture.
- Recherche de membres, import de contacts, blocage et signalement.
- Pièces jointes via les sélecteurs système, stockage privé attendu dans Supabase.
- Profil, suppression de compte et configuration TOTP.
- Partage ponctuel de position sous forme de lien cartographique (position partagée une seule fois, sans suivi en arrière-plan).
- Invitation des contacts non inscrits via l’application SMS avec un lien vers l’application Web.
- Flux d’inscription/validation du numéro BIIC CHAT par code envoyé à l’e-mail (branche/PR séparée, déploiement serveur encore requis).

## Priorité P0 — avant toute publication publique

1. **CI et compilation** : faire passer `flutter pub get`, `flutter analyze`, `flutter test`, build Web et build Android; conserver les résultats CI dans les PR.
2. **Configuration de production** : vérifier les paramètres Supabase, les clés publiques de build, les secrets Edge Functions et les journaux sans jamais exposer de secret côté client.
3. **Migrations** : réconcilier l’historique des migrations numérotées dupliquées avant tout `supabase db push`; sauvegarder et vérifier l’état distant avant changement.
4. **Sécurité** : auditer RLS pour chaque table, fonctions `SECURITY DEFINER`, accès Storage, anti-abus et confidentialité de la recherche de numéros.
5. **Autorisations mobiles** : tester autorisation, refus et refus définitif sur Android; générer et configurer réellement iOS/Info.plist avant d’annoncer cette plateforme.
6. **Identité téléphonique** : vérifier qu’un numéro n’est trouvable qu’après validation e-mail/code et que les erreurs/rate limits ne révèlent pas l’existence d’un compte.

## Priorité P1 — fonctions de messagerie essentielles à compléter

- Notifications de nouveaux messages et gestion des jetons par appareil (nécessite un fournisseur push et des secrets/configurations de plateforme).
- Messages audio/notes vocales (enregistrement, lecture, limites de taille, permission micro contextuelle).
- Répondre à un message, réactions, modification et suppression avec règles serveur et tests RLS.
- Recherche dans l’historique des conversations, pagination et chargement progressif pour les longues discussions.
- Administration des groupes : rôles, ajout/retrait de membres, départ et suppression contrôlée du groupe.
- Partage de position avec confirmation claire avant l’envoi; aucun suivi en arrière-plan.


## Priorité P2 — fonctionnalités avancées, à planifier séparément

- Événements de calendrier ou rappels seulement si un cas d’usage précis est retenu.
- Appareils liés / connexion par QR dédiée (différente du QR de double authentification).
- Chiffrement de bout en bout avec conception cryptographique et gestion des clés sérieuses; ne pas prétendre qu’il existe tant qu’il n’est pas implémenté et audité.
- Sauvegarde/export contrôlé des données, outils d’accessibilité et améliorations réseau hors ligne.

## Critères de validation de chaque fonctionnalité

- Aucune régression des messages, des contacts, des comptes ou des données existantes.
- Permissions demandées au moment de l’action et fonctionnalité dégradée proprement en cas de refus.
- Contrôles d’accès côté serveur (RLS/Edge Functions), pas uniquement dans l’interface.
- Tests unitaires, tests d’intégration quand c’est possible, revue des migrations et CI verte.
- Documentation des limites connues et des paramètres requis avant déploiement.

## Limites de cette feuille de route

Les changements sur une branche GitHub ne sont pas automatiquement déployés dans Supabase ou sur les téléphones. La validation e-mail, les notifications push, la configuration iOS, les secrets externes et les tests sur appareil nécessitent encore des étapes spécifiques avant la production.

