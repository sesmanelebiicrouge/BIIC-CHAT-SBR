# 🔧 Guide de Correction - SMS OTP non reçu dans BIIC CHAT

Vous êtes au bon endroit. Suivez ce guide étape par étape pour corriger l'erreur d'envoi de SMS.

---

## 🎯 Diagnostic rapide

Avant de commencer, testez directement dans Supabase pour voir si le SMS part ou s'il y a une erreur :

**Dans Supabase :**
1. Allez dans **Authentication → Users**
2. Cliquez sur **"Create New User"**
3. Choisir **"Phone"** (pas Email)
4. Numéro : `+2250700000000`
5. Mot de passe : `Test123!`
6. Cliquez **"Create User"**

**Résultat attendu :**
- ✅ SMS reçu = Twilio fonctionne, le problème est dans l'app
- ❌ Erreur à l'écran = Configuration Supabase/Twilio incorrecte
- ❌ Aucun SMS, pas d'erreur = Twilio silencieusement bloqué

---

## ⚠️ Erreurs les plus courantes et solutions

### Erreur 1 : "Invalid message-capable Twilio phone number for this destination"

**Cause :** Vous utilisez un numéro Twilio standard au lieu de **Twilio Verify**.

**Solution :**
1. Allez dans **Supabase Console → Authentication → Providers → Phone**
2. Dans **"SMS Configuration"**, sélectionnez **"Twilio Verify"** (pas "Twilio")
3. Dans le champ **"Messaging Service SID"**, mettez votre **Service SID Twilio Verify** (commence par `VA...`)
   - **Pas** votre numéro Twilio
   - **Pas** votre Messaging Service SID normal (commence par `MG...`)
4. Cliquez **"Save"**
5. Testez à nouveau

---

### Erreur 2 : "SMS provider not configured"

**Cause :** Le provider Phone n'est pas activé dans Supabase.

**Solution :**
1. Allez dans **Supabase Console → Authentication → Providers**
2. Cherchez **"Phone"**
3. Cliquez sur le toggle bleu pour **"Enable Phone provider"**
4. Cliquez **"Save"**
5. Testez à nouveau

---

### Erreur 3 : "Twilio account error" ou "Account SID incorrect"

**Cause :** Les identifiants Twilio sont mal saisis ou expirés.

**Solution :**
1. Ouvrez **Twilio Console → Account Info**
2. Copiez exactement le **Account SID** (commence par `AC...`)
3. Copiez exactement l'**Auth Token**
4. Allez dans **Supabase Console → Authentication → Providers → Phone**
5. Videz les champs et refaites les copier-coller :
   - **Account SID** : `AC...`
   - **Auth Token** : le token complet
   - **Messaging Service SID** : `VA...` (Twilio Verify) ou `MG...` (Messaging Service)
6. Cliquez **"Save"**
7. Testez à nouveau

---

### Erreur 4 : "Twilio service unavailable" ou pas de SMS reçu

**Cause :** Manque de crédit Twilio OU Côte d'Ivoire (+225) n'est pas supportée.

**Solution A : Vérifier le crédit**
1. Allez dans **Twilio Console → Account Info**
2. Regardez la section **"Balance"** ou **"Credits"**
3. Si le solde est 0 ou négatif :
   - Ajoutez des crédits (carte de crédit)
   - Ou demandez un crédit d'essai à Twilio

**Solution B : Vérifier la couverture SMS Côte d'Ivoire**
1. Allez dans **Twilio Console → Messaging → Coverage**
2. Cherchez **"Ivory Coast"** ou **"+225"**
3. Statut :
   - ✅ Vert = supporté
   - ⚠️ Orange = limité
   - ❌ Rouge = non supporté
4. Si rouge ou orange :
   - Contacter [Twilio Support](https://www.twilio.com/console/support/tickets)
   - Demander l'activation de SMS pour Côte d'Ivoire

---

### Erreur 5 : Compte Twilio en essai / trial

**Cause :** En mode essai, Twilio ne peut envoyer des SMS que vers des numéros **vérifiés**.

**Solution :**
1. Allez dans **Twilio Console → Phone Numbers → Verified Caller IDs** (ou **"Manage Numbers"**)
2. Vérifiez le numéro de test `+2250700000000` :
   - Cliquez sur **"Verify a Number"**
   - Entrez `+2250700000000`
   - Twilio vous envoie un code SMS
   - Entrez le code pour confirmer
3. Testez à nouveau depuis Supabase

**Alternative :** Passer du mode essai au mode production (ajouter un moyen de paiement).

---

## 🛠️ Checklist complète avant de tester

Cochez chaque point :

- [ ] **Supabase Console → Authentication → Providers → Phone**
  - [ ] Toggle **"Enable Phone provider"** est **ON** (bleu)
  
- [ ] **SMS Configuration dans Supabase**
  - [ ] Fournisseur SMS = **"Twilio"** ou **"Twilio Verify"** ❓ (voir ci-dessous)
  - [ ] Account SID = `AC...` (commence par AC, 32 caractères)
  - [ ] Auth Token = long token (peut contenir des caractères spéciaux)
  - [ ] Service/Message SID :
    - Si "Twilio Verify" : `VA...` (Twilio Verify Service SID)
    - Si "Twilio" : `MG...` (Messaging Service SID) OU `+1...` (Twilio Phone Number)

- [ ] **Twilio Console → Account Info**
  - [ ] Account SID visible et copiable
  - [ ] Auth Token visible et copiable
  - [ ] Solde/Balance **> 0 €/$**

- [ ] **Twilio Console → Messaging**
  - [ ] Vous avez un **Messaging Service** actif (ou un numéro Twilio)
  - [ ] Service SID = `MG...` (format normal) ou `VA...` (format Verify)

- [ ] **Twilio Console → Phone Numbers**
  - [ ] Au moins **1 numéro actif** (format `+1...`)
  - [ ] OU un **Verify Service** avec au moins 1 numéro configuré

- [ ] **Supabase OTP Settings**
  - [ ] OTP Length = `6` ✅
  - [ ] OTP Expiry = `600` secondes ✅
  - [ ] Max Attempts = `3` ou `5` ✅

---

## ⚡ Quelle configuration choisir : "Twilio" vs "Twilio Verify" ?

**Recommandation : Utiliser "Twilio Verify"** (plus fiable pour production)

| Critère | Twilio | Twilio Verify |
|---------|--------|---------------|
| **Fournisseur SMS** | Service SID (`MG...`) ou Phone Number | Service SID (`VA...`) |
| **Fiabilité** | Moyenne | ⭐⭐⭐⭐⭐ (meilleure) |
| **Coût** | $$$ | $$$ (parfois moins cher) |
| **Zones supportées** | Certaines régions uniquement | Plus de régions |
| **Pour Côte d'Ivoire** | ⚠️ Souvent bloqué | ✅ Généralement ok |

**Donc, si vous avez un problème avec "Twilio", essayez "Twilio Verify".**

---

## 📋 Procédure pas à pas pour corriger

### Étape 1 : Vérifier Twilio

1. Ouvrez **https://www.twilio.com/console**
2. Allez dans **Account Info**
3. Notez :
   - `Account SID` = `AC...`
   - `Auth Token` = le token
4. Allez dans **Messaging → Services** (ou **Verify → Services**)
5. Créez ou sélectionnez un service :
   - Si **Messaging Service** : notez `Service SID` = `MG...`
   - Si **Verify Service** : notez `Service SID` = `VA...`
6. Allez dans **Account Info** et vérifiez le solde (Balance)
   - Doit être **> 0**

---

### Étape 2 : Configurer Supabase

1. Ouvrez **https://app.supabase.com**
2. Sélectionnez votre projet
3. Allez dans **Authentication → Providers**
4. Cliquez sur **"Phone"**
5. Cochez **"Enable Phone provider"**
6. Dans **"SMS Configuration"** :
   - Choisissez **"Twilio Verify"** (recommandé)
   - Collez :
     - `Account SID` : `AC...` (depuis Twilio)
     - `Auth Token` : le token complet (depuis Twilio)
     - `Messaging Service SID` : `VA...` (depuis Twilio Verify)
7. Cliquez **"Save"**
8. Attendez 30 secondes

---

### Étape 3 : Tester depuis Supabase

1. Restez dans **Supabase Console**
2. Allez dans **Authentication → Users**
3. Cliquez **"Create New User"**
4. Remplissez :
   - **Type** : Phone
   - **Phone Number** : `+2250700000000`
   - **Password** : `Test123!`
5. Cliquez **"Create User"**
6. **Attendez 10-15 secondes**

**Résultat attendu :**
- ✅ Vous recevez un SMS avec un code à 6 chiffres
- ❌ Erreur visible à l'écran = notez le message exact
- ❌ Aucune erreur mais pas de SMS = le problème vient de Twilio (crédit, zone, etc.)

---

### Étape 4 : Si c'est bon, tester dans l'app BIIC CHAT

1. Ouvrez l'app BIIC CHAT sur votre téléphone
2. Allez à l'écran **"Créer votre compte"**
3. Entrez un numéro ivoirien : `07 00 00 00 00`
   - L'app le convertit automatiquement en `+2250700000000`
4. Entrez un mot de passe
5. Cliquez **"Créer mon compte"**
6. **Attendez 10-15 secondes**

**Résultat attendu :**
- ✅ SMS reçu avec un code
- ✅ Écran de vérification du code s'affiche
- ✅ Entrez le code et créez le compte

---

## 🚨 Si ça ne marche toujours pas

### Vérifier les logs Supabase

1. Allez dans **Supabase Console → Logs**
2. Cliquez sur l'onglet **"Logs"** ou **"Auth"**
3. Cherchez une ligne contenant :
   - "SMS"
   - "Twilio"
   - "OTP"
   - "phone_provider"
4. Notez l'erreur exacte

### Vérifier les logs Twilio

1. Allez dans **Twilio Console → Debugger**
2. Cherchez **"Message Logs"** ou **"Recent Logs"**
3. Cliquez sur le SMS qui a échoué
4. Regardez le **"Status"** et le **"Error Code"**

### Contacter le support

Si les logs ne vous aident pas :
- **Twilio** : https://www.twilio.com/console/support/tickets
  - Mentionnez : Account SID, le numéro testé, l'erreur
- **Supabase** : https://supabase.com/docs/guides/auth/phone-login
  - Ou ouvert une issue sur GitHub

---

## ✅ Résumé rapide

1. **Twilio Console** : Vérifier Account SID, Auth Token, crédit, Verify Service SID
2. **Supabase** : Configurer Phone Provider + Twilio Verify
3. **Test Supabase** : Créer un utilisateur avec `+2250700000000` depuis Supabase
4. **Si SMS arrive** : Test dans l'app BIIC CHAT
5. **Si SMS n'arrive pas** : Vérifier logs Supabase + logs Twilio
6. **Si toujours bloqué** : Contacter Twilio (crédit? zone supportée?)

