# Accès appareil

BIIC CHAT prend en charge la sélection de photos/médias et de fichiers avec les sélecteurs système, la prise de photos, l’import de contacts et le partage d’un contact, ainsi que l’ouverture du composeur téléphonique.

Les permissions sont séparées et doivent être demandées au moment d’utiliser la fonctionnalité. BIIC CHAT ne demande pas un accès complet permanent au téléphone. Les sélecteurs système sont préférés pour les fichiers et les médias afin d’éviter un accès général au stockage.

Voir [docs/DEVICE_PERMISSIONS.md] pour les permissions Android/iOS, les justifications iOS requises et les contrôles avant publication.

Le dépôt ne contient pas encore de projet iOS généré. La configuration iOS doit être fusionnée dans Info.plist lorsque la plateforme iOS est créée. Les fonctionnalités de partage de localisation, d’accès calendrier et d’alarmes intégrées ne sont pas encore implémentées; les méthodes de demande d’autorisation seules ne les rendent pas fonctionnelles.
