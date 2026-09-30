# Publication BIIC CHAT

Le dépôt contient maintenant un workflow de release qui prépare automatiquement un Android App Bundle (AAB) et une version Web.

## Android / Google Play

Le workflow attend ces secrets GitHub :

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_PROPERTIES`

Le fichier `ANDROID_KEY_PROPERTIES` doit contenir :

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=upload-keystore.jks
```

La clé privée du keystore ne doit jamais être commitée dans Git.

Le workflow génère le projet Android, utilise l'identifiant d'application `com.biicchat.biic_chat_sbr`, puis produit `app-release.aab`.

Google Play exige actuellement qu'une nouvelle application ou une mise à jour cible Android 16 / API 36 ou supérieur à partir du 31 août 2026.

## Publication effective

La génération de l'AAB et son envoi à Google Play nécessitent encore :
1. un compte Google Play Console appartenant au propriétaire du projet ;
2. l'enregistrement de l'application dans Play Console ;
3. une clé d'upload Android ;
4. les informations de fiche Play Store (nom, description, icône, captures d'écran, catégorie, contenu, confidentialité, etc.) ;
5. si l'envoi est automatisé, un compte de service Google Play Console et ses identifiants configurés comme secrets GitHub.

Ces éléments sont des accès privés au compte du propriétaire et ne doivent pas être copiés dans le code source ni envoyés dans une conversation.

## iOS

La génération et la signature iOS nécessitent macOS/Xcode et un compte Apple Developer. Le dépôt ne peut pas être signé et envoyé à l'App Store depuis l'environnement Linux du workflow Android.

## Important

Le projet ne demande pas un accès illimité aux fichiers du téléphone. Il utilise les sélecteurs système et les permissions nécessaires pour les photos, caméra, fichiers et contacts, conformément au modèle de permissions de la plateforme.
