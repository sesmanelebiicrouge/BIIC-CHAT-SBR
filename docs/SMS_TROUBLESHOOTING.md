# 🔧 Débogage SMS/OTP Twilio - BIIC CHAT

Vous ne recevez pas de code SMS ? Suivez ce guide diagnostique.

---

## ⚡ Checklist rapide (5 min)

- [ ] **Supabase Console** : Allez dans **Authentication → Providers → Phone**
  - [ ] Le toggle **"Enable Phone provider"** est **ON** (bleu)
  - [ ] La section "SMS Configuration" affiche **"Twilio"** (pas "Twilio Verify")
  - [ ] Les 3 champs sont remplis :
    - Account SID (commence par `AC...`)
    - Auth Token (long string)
    - Twilio Number OU Messaging Service SID

- [ ] **Twilio Console** : Allez dans **Account Info**
  - [ ] Vous avez au moins **1 $ ou plus** de crédit
  - [ ] Pas de message rouge "Account suspended"

- [ ] **Supabase Logs** : Allez dans **Logs** et cherchez "SMS" ou "Twilio"
  - [ ] Avez-vous des erreurs de type "SMS provider not configured" ?
  - [ ] Avez-vous des erreurs de type "Twilio authentication failed" ?

---

## 🔍 Étapes diagnostiques détaillées

### Étape 1 : Vérifier que Supabase envoie vraiment à Twilio

1. Ouvrez **Supabase Console → Logs**
2. Filtrez par `level:error` ou `level:warn`
3. Cherchez des lignes contenant :
   - "SMS"
   - "OTP"
   - "Twilio"
   - "phone_provider"

**Si vous voyez une erreur :**
```
SMS provider not configured
```
→ C'est que Twilio **n'est pas activé** dans Supabase. Allez à **Authentication → Providers → Phone** et refaites la configuration.

---

### Étape 2 : Vérifier que Twilio peut envoyer des SMS

1. Ouvrez **Twilio Console → Account Info**
2. Vérifiez :
   - ✅ Account SID commence par `AC`
   - ✅ Auth Token n'est pas vide
   - ✅ Votre solde est > 0 €/$ (section "Balance")

3. Allez dans **Twilio Console → Phone Numbers → Manage Numbers → Active Numbers**
   - ✅ Avez-vous au moins **1 numéro Twilio actif** ?
   - ✅ Le numéro est-il de format `+...` (exemple : `+1234567890`) ?

**Si vous n'avez pas de numéro :**
- Acheter un numéro Twilio dans **Phone Numbers → Buy a Number**
- OU créer un **Messaging Service** dans **Messaging → Services**

---

### Étape 3 : Tester l'envoi direct depuis Supabase

1. Ouvrez **Supabase Console → Authentication → Users**
2. Cliquez sur **"Create New User"** (bouton bleu)
3. Remplissez :
   - **Email** ou **Phone** : sélectionnez **Phone**
   - **Phone Number** : `+2250700000000` (numéro test Côte d'Ivoire)
   - **Password** : `Test12345!`
4. Cliquez sur **"Create User"**

**Attendez 10 secondes :**
- ✅ Si vous recevez un SMS → Twilio fonctionne ✓
- ❌ Si rien n'arrive → Allez à l'étape 4

---

### Étape 4 : Vérifier les logs Twilio

1. Ouvrez **Twilio Console → Debugger**
2. Dans l'onglet **"Message Logs"**, cherchez les SMS récents
3. Cliquez sur la ligne SMS pour voir les détails :
   - **Status** : `queued`, `sent`, `delivered`, `failed`
   - **Error Code** : Si `failed`, notez le code d'erreur

**Erreurs courantes Twilio :**

| Code | Signification | Solution |
|------|---------------|----------|
| `21211` | "Invalid 'To' Phone Number" | Le format du numéro est mauvais. Twilio attend `+...` |
| `21608` | "SMS has been blocked" | Twilio a bloqué le numéro (souvent zone non supportée) |
| `21614` | "Account Suspended" | Votre compte Twilio est suspendu (pas de paiement ?) |
| `20003` | "Account disabled" | Compte désactivé par Twilio |
| `32603` | "Wireless Carrier Gateways are not available" | Région non supportée pour SMS |

---

### Étape 5 : Vérifier la couverture SMS Côte d'Ivoire

1. Ouvrez **Twilio Console → Messaging → Coverage**
2. Cherchez **"Côte d'Ivoire"** ou **"Ivory Coast"** ou **"+225"**
3. Vérifiez le statut :
   - ✅ Vert = SMS supporté
   - ⚠️ Orange = SMS limité/problématique
   - ❌ Rouge = SMS non supporté

**Si Côte d'Ivoire n'est pas supportée :**
- Contacter [support Twilio](https://www.twilio.com/console/support/tickets)
- Demander l'activation de la couverture SMS pour +225

---

## 🛠️ Solutions rapides

### Solution 1 : Reconfigurer Twilio dans Supabase

1. Allez dans **Supabase → Authentication → Providers → Phone**
2. Cliquez sur **"Phone"** pour l'ouvrir
3. Dans **"SMS Configuration"**, décochez puis recochez **"Twilio"**
4. Videz et refaites les 3 champs :
   - Account SID (copier-coller depuis Twilio Console)
   - Auth Token (copier-coller depuis Twilio Console)
   - Twilio Number **OU** Messaging Service SID
5. Cliquez **"Save"**
6. Attendez 30 secondes et testez

---

### Solution 2 : Utiliser un Messaging Service au lieu d'un numéro

**C'est souvent plus fiable :**

1. Ouvrez **Twilio Console → Messaging → Services**
2. Créez un nouveau service ou utilisez-en un existant
3. Copiez le **Service SID** (commence par `MG...`)
4. Allez dans **Supabase → Authentication → Providers → Phone**
5. Dans le champ **"Twilio Phone Number"**, collez le **Service SID** à la place
6. Cliquez **"Save"**

---

### Solution 3 : Vérifier le format du numéro

L'app normalise automatiquement les numéros, mais Twilio doit recevoir un format strictement international.

**Format accepté :** `+2250700000000` (13 chiffres pour Côte d'Ivoire)

**Formats rejetés :**
- `07 00 00 00 00` ❌ (pas de `+`)
- `225 07 00 00 00 00` ❌ (pas de `+`)
- `+225 07 00 00 00 00` ✅ (correct, mais l'app le corrige)

---

## 📋 Si rien ne marche : liste de vérification finale

- [ ] Supabase Phone Provider est **activé**
- [ ] Twilio Account SID et Auth Token sont **corrects** (copiés hier ? Retestez)
- [ ] Twilio a **des crédits** (solde > 0)
- [ ] Côte d'Ivoire (+225) est **supportée** dans Twilio Coverage
- [ ] Le numéro de test `+2250700000000` est au format **international correct**
- [ ] Les **logs Twilio** ne montrent pas d'erreur `21608` ou `21614`
- [ ] Vous avez attendu **10-30 secondes** après le clic (SMS n'est pas instantané)
- [ ] Vous avez testé depuis **Supabase Console d'abord** (avant l'app)

---

## 📞 Support recommandé

Si vous êtes bloqué après ces étapes :

1. **Twilio** : Ouvrez un ticket à https://www.twilio.com/console/support/tickets
   - Mentionnez : Account SID, numéro de test, erreur exacte

2. **Supabase** : Consultez https://supabase.com/docs/guides/auth/phone-login
   - Cherchez la section "Twilio Configuration"

3. **BIIC CHAT Logs** : Allez dans **Supabase Logs** et exportez les 50 dernières lignes
   - Les logs aideront à identifier le point de rupture

---

## ✅ Résumé

1. **Test Supabase Console** : Si ça marche → le problème est dans l'app
2. **Test Twilio Console** : Si les SMS n'y arrivent pas → Twilio est bloqué
3. **Test Logs** : Cherchez l'erreur exacte pour la corriger

