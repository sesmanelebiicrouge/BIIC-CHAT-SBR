# Configuration Twilio SMS pour BIIC CHAT

Ce guide explique comment configurer Twilio et Supabase pour l'authentification par SMS dans BIIC CHAT.

## 📱 Indices nécessaires

Vous devez avoir accès à :

### 1. **Twilio Console** (https://www.twilio.com/console)

#### Données à récupérer :

**A. Account SID**
- Aller dans : **Twilio Console → Account Info**
- Copier le **Account SID** (commence par `AC...`)
- Exemple : `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**B. Auth Token**
- Même page : **Account Info**
- Copier l'**Auth Token** (long token secret)
- ⚠️ Ne jamais commiter cet token dans Git
- Exemple : `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**C. Numéro Twilio ou Messaging Service SID**

**Option C.1 : Utiliser un numéro Twilio**
- Aller dans : **Phone Numbers → Manage Numbers → Active Numbers**
- Copier le **numéro complet** (format : +1234567890 ou similaire)
- Exemple pour test : `+1234567890`

**Option C.2 : Utiliser un Messaging Service SID** (recommandé pour production)
- Aller dans : **Messaging → Services**
- Créer un nouveau service SMS si nécessaire
- Copier le **Service SID** (commence par `MG...`)
- Exemple : `MGxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### 2. **Supabase Console** (https://app.supabase.com)

#### Données à récupérer :

**D. Supabase URL**
- Aller dans : **Project Settings → API**
- Copier l'**URL du projet** (format : `https://xxxxx.supabase.co`)
- Exemple : `https://ktiawqonbjhzzghksngr.supabase.co`

**E. Supabase Publishable Key (clé publique)**
- Même page : **API → Project API keys**
- Copier la clé **`public / anon`**
- Elle commence par `sb_public_...` ou `eyJhbGciOi...`
- Exemple : `sb_publishable_Fc0Ekq2igdnN-_dxIcDijQ_M0evXXoB`

⚠️ **NE JAMAIS utiliser la clé `service_role` dans le client Flutter**

---

## ⚙️ Étapes de configuration dans Supabase

### Étape 1 : Activer le provider Phone

1. Aller dans **Authentication → Providers**
2. Chercher **"Phone"**
3. Cliquer sur **"Phone"** pour l'ouvrir
4. Activer le toggle **"Enable Phone provider"**
5. Cliquer sur **"Save"**

### Étape 2 : Configurer Twilio dans le provider Phone

1. Rester dans **Authentication → Providers → Phone**
2. Dans la section **"SMS Configuration"**, choisir **"Twilio"** en tant que fournisseur
3. Remplir les champs :

| Champ | Valeur | Source |
|-------|--------|--------|
| **Account SID** | `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Twilio Console → Account Info |
| **Auth Token** | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Twilio Console → Account Info |
| **Twilio Phone Number** OU **Messaging Service SID** | `+1234567890` OU `MGxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Twilio Console → Phone Numbers OU Messaging Services |

4. Cliquer sur **"Save"**

### Étape 3 : Configurer les paramètres de l'OTP SMS

1. Rester dans **Authentication → Providers → Phone**
2. Vérifier les paramètres **OTP Settings** :
   - **OTP Expiry** : `600` secondes (10 minutes) — acceptable
   - **OTP Length** : `6` digits — ✅ correspond au code du projet
   - **Max Attempts** : `3` ou `5` (limite de tentatives)

3. Cliquer sur **"Save"**

### Étape 4 : Tester la configuration

1. Aller dans **Authentication → Users**
2. Cliquer sur **"Create New User"**
3. Choisir **"Phone"** au lieu d'Email
4. Entrer un numéro au format international : `+2250700000000` (exemple Côte d'Ivoire)
5. Définir un mot de passe
6. Cliquer sur **"Create User"**
7. ✅ Si pas d'erreur, Twilio envoie un SMS au numéro

---

## 🧪 Valider que tout marche

### Test 1 : Depuis Supabase
1. **Authentication → Users → Create New User**
2. Choisir **Phone**
3. Entrer : `+2250700000000`
4. Attendre 10 secondes
5. ✅ Vous devez recevoir un SMS avec un code à 6 chiffres

### Test 2 : Depuis l'app BIIC CHAT
1. Ouvrir l'application Flutter BIIC CHAT
2. Aller à l'écran d'inscription
3. Entrer un numéro ivoirien : `07 00 00 00 00` (le code force le format `+225...`)
4. Choisir un mot de passe
5. Cliquer sur **"Continuer"**
6. ✅ Vous recevez un SMS avec un code
7. Copier le code dans l'app
8. Cliquer sur **"Valider"**
9. ✅ Compte créé, vous êtes connecté

### Test 3 : Changement de numéro
1. Connecté à l'app
2. Aller dans **Paramètres → Changer de numéro**
3. Entrer un nouveau numéro : `05 00 00 00 00`
4. Cliquer sur **"Continuer"**
5. ✅ Un SMS doit arriver au nouveau numéro
6. Valider le code
7. ✅ Numéro changé

---

## 🚨 Erreurs courantes et solutions

| Erreur | Cause | Solution |
|--------|-------|----------|
| "SMS provider not configured" | Twilio non activé dans Supabase | Vérifier que Phone provider est **ON** et Twilio est configuré |
| "Invalid phone number" | Format incorrect | Utiliser format international : `+225` pour Côte d'Ivoire |
| "Twilio account error" | Account SID ou Auth Token incorrect | Vérifier dans Twilio Console → Account Info |
| "Twilio service unavailable" | Pas de crédits Twilio ou zone non supportée | Vérifier solde Twilio et zones de couverture SMS |
| "Rate limit exceeded" | Trop de tentatives d'envoi | Attendre 5 minutes avant de réessayer |

---

## 📋 Checklist avant production

- [ ] Account SID Twilio récupéré et vérifié
- [ ] Auth Token Twilio copié (stocké de manière sécurisée, jamais en dur)
- [ ] Numéro Twilio ou Messaging Service SID configuré
- [ ] Provider Phone activé dans Supabase
- [ ] Credentials Twilio remplis dans Supabase
- [ ] OTP Settings vérifiés (6 digits, 600s expiry)
- [ ] Test d'inscription réussi avec SMS reçu
- [ ] Test de changement de numéro réussi
- [ ] Test de reset mot de passe par SMS réussi
- [ ] Variables de build Flutter configurées :
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`

---

## 🔐 Sécurité

⚠️ **Points critiques :**

1. **Ne jamais commiter l'Auth Token Twilio** dans Git
2. **Ne jamais utiliser la clé `service_role` Supabase** dans Flutter
3. **Garder les secrets dans GitHub Secrets** ou `.env` local (non commité)
4. **Tester d'abord en développement** avant la production
5. **Monitorer les coûts Twilio** (SMS n'est pas gratuit à grande échelle)

---

## 📞 Support

Si vous avez des erreurs spécifiques :

1. Aller dans **Supabase Console → Logs**
2. Chercher les erreurs SMS/OTP
3. Vérifier les credentials Twilio dans **Twilio Console → Debugger**
4. Confirmer que le numéro cible supporte les SMS (Côte d'Ivoire +225)

---

## 🎯 Résumé rapide

**En 5 étapes :**

1. Récupérer `Account SID` et `Auth Token` depuis Twilio Console
2. Récupérer un numéro Twilio ou créer un Messaging Service
3. Aller dans Supabase → Authentication → Providers → Phone
4. Choisir **Twilio** et remplir les 3 champs
5. Cliquer **Save** et tester
