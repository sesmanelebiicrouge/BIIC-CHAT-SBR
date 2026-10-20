# Activation de l’inscription par e-mail — BIIC CHAT

Le code de l’application prend désormais en charge l’inscription et la connexion par e-mail en plus du téléphone. Pour que la confirmation par code fonctionne en production, vérifiez les réglages Supabase ci-dessous.

## Réglages Supabase

1. Ouvrir le projet BIIC CHAT dans Supabase.
2. Aller dans **Authentication → Sign In / Providers** (le libellé peut varier selon l’interface).
3. Activer le fournisseur **Email** et autoriser les inscriptions par e-mail.
4. Activer la confirmation des adresses e-mail si elle est exigée en production.
5. Dans **Authentication → Email Templates → Confirm signup**, utiliser un modèle qui affiche le code OTP, par exemple :

   `Votre code de confirmation BIIC CHAT est : {{ .Token }}`

   L’écran de l’application attend un code à 6 chiffres et le valide avec Supabase Auth. Un modèle qui n’envoie qu’un lien de confirmation ne correspond pas à cet écran.
6. Dans **Authentication → URL Configuration**, vérifier que l’URL publique de BIIC CHAT est enregistrée comme Site URL et que les Redirect URLs correspondent aux URL utilisées par l’application.
7. Tester avec une adresse e-mail réelle à laquelle vous avez accès : inscription, réception du code, validation, déconnexion puis reconnexion.

## Sécurité et limites

- Ne jamais désactiver la vérification côté serveur pour contourner une erreur.
- Ne jamais mettre une clé `service_role`, un secret Supabase ou un secret Orange dans le code client.
- Le code client peut être publié sans secret serveur, mais les politiques RLS Supabase restent indispensables.
- Le lien public GitHub Pages ne sera mis à jour qu’après fusion dans `main` et réussite du workflow de publication.
