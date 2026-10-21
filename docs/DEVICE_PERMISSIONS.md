# Autorisations de l’appareil — BIIC CHAT

BIIC CHAT ne demande pas un « accès complet » permanent au téléphone. Android et iOS imposent des autorisations séparées, accordées par l’utilisateur. L’application demande chaque autorisation au moment où la fonctionnalité correspondante est utilisée, et doit rester utilisable lorsque l’utilisateur refuse une permission facultative.

## Fonctions et comportement attendu

- **Contacts** : l’écran Contacts et le partage d’un contact demandent l’accès aux contacts avant lecture. Seuls les numéros enregistrés et vérifiés sur BIIC CHAT peuvent être reconnus comme membres.
- **Photos, vidéos et fichiers** : utiliser les sélecteurs système (`image_picker` et `file_picker`). Ils donnent accès aux éléments choisis par l’utilisateur; ne pas demander un accès général au stockage.
- **Caméra** : l’autorisation est demandée quand l’utilisateur choisit de prendre une photo dans une discussion.
- **Microphone** : le service de permissions expose une demande dédiée, à appeler uniquement si BIIC CHAT enregistre de l’audio ou utilise un appel intégré. Les appels Jitsi actuellement ouverts dans une application/un navigateur externe doivent demander les permissions dans cette application externe.
- **Localisation** : le partage de position courante est proposé explicitement dans le menu des pièces jointes. La permission n’est demandée qu’après ce choix. La position est envoyée sous forme de lien Google Maps dans le message; aucun suivi en arrière-plan n’est effectué.
- **Calendrier** : la méthode de demande d’accès calendrier est préparée. Ajouter la lecture/écriture réelle des événements seulement avec une fonctionnalité explicite et un consentement clair.
- **Notifications** : demande dédiée disponible; l’app doit expliquer pourquoi elle souhaite afficher des notifications avant de demander la permission. Les notifications push ne sont pas considérées comme opérationnelles sans configuration de fournisseur et de jetons.
- **Horloge / alarmes** : il n’existe pas d’autorisation générale pour lire « l’horloge ». Android traite les alarmes exactes comme un accès spécial séparé (`SCHEDULE_EXACT_ALARM`) qui ouvre les paramètres système. Ne l’ajouter que si BIIC CHAT planifie réellement des alarmes exactes. Les rappels simples doivent préférer les mécanismes standards de notifications.

## Android

Le manifeste déclare caméra, microphone, contacts, localisation approximative/précise, calendrier et notifications. Les déclarations seules n’accordent pas l’accès : le code doit demander la permission au bon moment. Ne pas ajouter `MANAGE_EXTERNAL_STORAGE`, `READ_PHONE_STATE` ou d’autres permissions larges sans besoin démontré.

Les sélecteurs système de `image_picker`/`file_picker` évitent de demander un accès global aux photos/fichiers. Le partage de position utilise la localisation au premier plan uniquement. Si le produit adopte plus tard une galerie intégrée qui lit toute la médiathèque, réévaluer les permissions Android selon la version du système.

## iOS

Le dépôt actuel ne contient pas de projet iOS généré (`ios/Runner/Info.plist`). Après génération/configuration de la plateforme iOS, fusionner les clés de justification suivantes dans `ios/Runner/Info.plist` avant de compiler :

- `NSCameraUsageDescription` — « BIIC CHAT utilise la caméra lorsque vous prenez une photo à envoyer. »
- `NSMicrophoneUsageDescription` — « BIIC CHAT utilise le microphone lorsque vous enregistrez un message audio ou utilisez un appel intégré. »
- `NSContactsUsageDescription` — « BIIC CHAT utilise vos contacts lorsque vous choisissez de les importer ou de partager un contact. »
- `NSLocationWhenInUseUsageDescription` — « BIIC CHAT utilise votre position uniquement lorsque vous choisissez de la partager. »
- `NSCalendarsFullAccessUsageDescription` — « BIIC CHAT accède à votre calendrier uniquement si vous choisissez une fonctionnalité de calendrier. »
- `NSCalendarsWriteOnlyAccessUsageDescription` — « BIIC CHAT ajoute un événement uniquement lorsque vous le demandez. »

Ne pas demander la localisation en arrière-plan ni l’accès complet aux photos si les sélecteurs système suffisent. Le texte des raisons doit correspondre exactement aux fonctionnalités effectivement livrées.

## Vérifications avant publication

1. Exécuter `flutter pub get`, `flutter analyze` et `flutter test` avec la version Flutter du projet.
2. Sur un appareil Android, tester autoriser, refuser et refuser définitivement chaque permission.
3. Vérifier que choisir une photo ou un document continue de fonctionner via les sélecteurs système sans permission de stockage générale.
4. Tester le partage de position en autorisant/refusant la localisation, avec le service de localisation désactivé et sur le Web.
5. Tester contacts, caméra, notifications et calendrier seulement lorsque leurs fonctions respectives sont utilisées.
6. Générer/configurer le projet iOS et tester les dialogues d’autorisation et les clés Info.plist avant d’annoncer la prise en charge iOS.

Cette documentation distingue les permissions déclarées des fonctionnalités effectivement livrées. La déclaration d’une permission ne suffit jamais à activer une fonctionnalité.
