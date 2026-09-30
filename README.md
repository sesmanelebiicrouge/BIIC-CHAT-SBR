# BIIC-CHAT-SBR

BIIC CHAT est une application Flutter de messagerie et de communication, conçue pour Android, iOS et le Web.

## État du projet

Le dépôt constitue une base de développement fonctionnelle, mais ce n'est pas encore une version prête à publier sur les stores. Les étapes restantes comprennent notamment le backend complet, l'authentification, la messagerie temps réel, les tests sur appareils réels et la génération des plateformes natives.

## Stack

- Flutter / Dart
- Material 3
- Supabase pour l'authentification, la base de données, le temps réel et le stockage
- Plugins Flutter pour images, fichiers, contacts et liens téléphoniques

## Développement local

flutter pub get
flutter create .
flutter analyze
flutter test
flutter run

flutter create . est nécessaire tant que les plateformes natives complètes Android/iOS ne sont pas présentes dans le dépôt.

## Configuration Supabase

Pour activer le backend, fournir les paramètres au lancement sans les mettre dans Git :

flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

Ne jamais commit une clé secrète de service Supabase. Utiliser uniquement la clé publique prévue pour le client et sécuriser les données avec RLS.

## Fonctionnalités déjà présentes

- interface de chat locale ;
- sélection d'images ;
- prise de photo ;
- sélection de fichiers ;
- lecture des contacts après autorisation ;
- ouverture du composeur téléphonique ;
- service de conversations Supabase préparé.

## Avant publication

1. Générer et vérifier Android/iOS.
2. Ajouter authentification et profils.
3. Implémenter messages persistants et temps réel.
4. Implémenter upload média avec règles Storage.
5. Ajouter notifications push.
6. Ajouter tests unitaires, widget et intégration.
7. Configurer signature Android et bundle release.
8. Configurer App Store Connect pour iOS.
9. Préparer politique de confidentialité, fiches stores et comptes de démonstration.
10. Effectuer les tests de sécurité, performance, permissions et récupération de compte.

## CI

GitHub Actions exécute flutter pub get, flutter analyze et flutter test sur les pushes et pull requests.

## Publication Google Play

Au 31 août 2026, les nouvelles applications et mises à jour Google Play doivent cibler Android 16 / API 36 ou supérieur. Vérifier les exigences actuelles de Play Console avant chaque soumission.
