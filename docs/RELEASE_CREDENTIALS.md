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


## iOS / Apple App Store

Le workflow `.github/workflows/ios.yml` prépare une build iOS avec Xcode 26 et peut envoyer automatiquement une IPA sur TestFlight.

Pour activer la publication TestFlight, configurer dans GitHub Actions :

### Variables du dépôt
- `APPLE_TEAM_ID`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_API_KEY_ID`

### Secrets du dépôt
- `APPSTORE_API_PRIVATE_KEY` — contenu du fichier `AuthKey_*.p8`
- `APPSTORE_CERTIFICATES_FILE_BASE64` — certificat de distribution Apple au format P12 encodé en Base64
- `APPSTORE_CERTIFICATES_PASSWORD` — mot de passe du P12

Le Bundle ID utilisé est `com.biicchat.biic_chat_sbr`. L'application doit d'abord être créée dans App Store Connect avec ce même identifiant. Apple exige actuellement que les apps envoyées sur App Store Connect soient construites avec Xcode 26 ou ultérieur et le SDK iOS 26 ou ultérieur.

Le workflow ne contient aucune clé privée Apple ou certificat : ces éléments restent dans GitHub Actions Secrets. L'envoi TestFlight utilise l'API App Store Connect.

## Validation Supabase avant publication

Les workflows Web, Android et iOS vérifient désormais que `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY` ne sont pas seulement présents : ils testent également l'authentification auprès du projet Supabase avant de produire/publier une release. Cela évite de mettre en ligne une build qui retourne `401 Invalid API key`.

Une clé client doit être une clé publishable (ou l'ancienne clé `anon` pendant la migration), jamais une clé `secret`/`service_role`. Supabase indique que les clés publishable sont destinées aux applications Web et mobiles.
