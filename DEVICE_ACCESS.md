# Accès appareil

BIIC CHAT prend désormais en charge :

- la sélection d’images dans la galerie ;
- la prise de photos avec la caméra ;
- la sélection de fichiers (PDF, documents, etc.) ;
- la lecture du répertoire de contacts ;
- l’ouverture du composeur téléphonique pour appeler un contact.

## Permissions mobiles

Le dépôt ne contient pas encore les dossiers Android/iOS générés par Flutter. Après avoir exécuté `flutter create .`, vérifiez les permissions suivantes :

### Android (`android/app/src/main/AndroidManifest.xml`)

Ajoutez dans la balise `<manifest>` :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
```

`file_picker` et `image_picker` gèrent généralement les sélecteurs système. Pour un appel, l’application ouvre le composeur ; elle ne compose pas automatiquement le numéro.

### iOS (`ios/Runner/Info.plist`)

Ajoutez :

```xml
<key>NSCameraUsageDescription</key>
<string>BIIC CHAT utilise la caméra pour envoyer des photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>BIIC CHAT utilise la galerie pour joindre des médias.</string>
<key>NSContactsUsageDescription</key>
<string>BIIC CHAT utilise vos contacts pour partager un contact.</string>
```

## Installation

```bash
flutter pub get
flutter create .
flutter run
```

Les autorisations sont demandées au moment où l’utilisateur utilise la fonctionnalité concernée.
