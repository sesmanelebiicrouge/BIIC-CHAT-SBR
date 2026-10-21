# BIIC CHAT SBR — audit de santé du projet

Date de vérification : 21 octobre 2026

Ce document distingue les vérifications effectuées à distance des contrôles qui exigent encore un essai sur appareil réel. Il ne constitue pas une certification de sécurité.

## État confirmé

- Le dépôt Flutter contient les modules d'authentification, conversations, pièces jointes, contacts, statuts, signalement/blocage et historique des appels.
- Le pipeline Flutter CI a terminé avec succès sur la version vérifiée : analyse/tests et build Web/Android debug.
- Les workflows CI et de déploiement ont été renforcés dans cette branche : les tests et builds de PR utilisent un jeton GitHub en lecture seule et désactivent la persistance des identifiants de checkout ; seul un job de déploiement déclenché depuis `main` reçoit `contents: write`. Les builds de branches différentes ne s'annulent plus mutuellement.
- Le déploiement GitHub Pages a terminé avec succès. URL : https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/
- Le projet Supabase répond et son historique distant comporte des migrations jusqu'à `20261021182947`.
- Les Edge Functions `send-sms` et `phone-registration` sont présentes et actives. Leur état « actif » ne prouve pas que tous les secrets Orange, le hook SMS Auth ou les crédits fournisseur sont correctement configurés.

## Corrections apportées dans cette branche

- Les boutons d'appel vérifient maintenant l'éligibilité de l'appel avant d'ouvrir Jitsi : session connectée, discussion accessible, discussion directe à deux participants, utilisateur membre et absence de blocage. Cela évite d'ouvrir une salle quand le backend refuserait l'enregistrement.
- L'enregistrement de l'historique réutilise cette validation côté service.

## Points de sécurité à traiter avec précaution

### 1. Protection contre les mots de passe compromis

L'avis Supabase Auth indique que la protection contre les mots de passe compromis est désactivée. L'activer dans les paramètres Auth du projet, puis tester l'inscription, le changement et la réinitialisation du mot de passe avant de considérer le changement terminé.

### 2. Fonctions SQL SECURITY DEFINER

L'advisor Supabase signale huit fonctions SECURITY DEFINER exécutables par le rôle `authenticated`. Ce n'est pas automatiquement une vulnérabilité : certaines sont nécessaires pour traverser les politiques RLS. Elles doivent cependant être revues individuellement pour confirmer les contrôles `auth.uid()`, les autorisations, le `search_path` fixe et le minimum de droits. Ne pas révoquer leurs permissions en bloc sans tests, car cela pourrait casser les conversations, les contacts ou la suppression de compte.

### 3. Table des codes d'inscription téléphonique

`public.phone_registration_codes` a RLS activé sans politique. Cela bloque l'accès direct via les rôles ordinaires et peut être volontaire si l'accès est exclusivement réalisé par un flux serveur privilégié. Vérifier le chemin d'accès attendu et garder les codes hors du client public ; ne pas ajouter de politique permissive juste pour faire disparaître l'avis.

### 4. Historique des migrations

Les anciens fichiers de migration numérotés ont des préfixes de version en doublon (`013`, `014`, `015`, `016`) alors que l'historique Supabase distant utilise des versions horodatées. Avant toute commande `supabase db push`, comparer chaque migration locale à l'historique distant et préparer une réconciliation non destructive. Ne pas renommer les migrations historiques ni rejouer leur SQL à l'aveugle sur la production.

## Limite importante des appels

À ce stade, l'application ouvre une salle Jitsi dans une application ou un navigateur externe. La validation préalable est améliorée, mais il n'y a pas encore de moteur d'appel WebRTC intégré avec sonnerie entrante, acceptation/refus, négociation média, bascule caméra/micro et gestion fiable des états d'appel dans BIIC CHAT. Ne pas annoncer les appels comme totalement intégrés tant que cette fonctionnalité n'a pas été implémentée et testée entre deux comptes sur Web et Android. Un service TURN et une stratégie de signalisation sécurisée seront nécessaires pour une bonne connectivité en réseaux mobiles/NAT.

## Vérifications de prépublication encore nécessaires

- Tester inscription/connexion par téléphone et e-mail, OTP, récupération de compte et suppression de compte.
- Tester en deux comptes distincts : message temps réel, accusés de lecture, blocage, pièces jointes privées, statuts et historique des appels.
- Vérifier permissions microphone/caméra/contacts/localisation sur Android réel et navigateur mobile.
- Confirmer les secrets Edge Function et le hook SMS dans le tableau de bord Supabase, sans copier les secrets dans Git ou le client.
- Activer la protection des mots de passe compromis puis exécuter à nouveau les tests d'authentification.
- Contrôler les advisors Supabase après chaque migration et vérifier que les buckets privés restent privés.
- Vérifier les clés de signature Android et les secrets de publication iOS avant toute diffusion dans un store.

## Liens de suivi

- Application Web : https://sesmanelebiicrouge.github.io/BIIC-CHAT-SBR/
- Dépôt : https://github.com/sesmanelebiicrouge/BIIC-CHAT-SBR
- Aide Supabase sur la protection des mots de passe : https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
- Aide Supabase sur le linter de base de données : https://supabase.com/docs/guides/database/database-linter
