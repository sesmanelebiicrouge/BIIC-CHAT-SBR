import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
const normalize = (value: string) => {
  let phone = value.trim().replace(/[\\s().-]/g, "");
  if (phone.startsWith("00")) phone = "+" + phone.slice(2);
  if (phone.startsWith("0")) phone = "+225" + phone.slice(1);
  if (!phone.startsWith("+")) phone = "+225" + phone;
  if (!/^\\+225(?:01|05|07)\\d{8}$/.test(phone)) throw new Error("Numéro invalide. Utilisez +225 suivi d'un numéro ivoirien 01, 05 ou 07.");
  return phone;
};
const hash = async (value: string) => {
  const result = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(result)].map((b) => b.toString(16).padStart(2, "0")).join("");
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "Méthode non autorisée." }, 405);
  const url = Deno.env.get("SUPABASE_URL"), anon = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const resendKey = Deno.env.get("RESEND_API_KEY"), from = Deno.env.get("PHONE_OTP_FROM_EMAIL");
  if (!url || !anon || !serviceKey || !resendKey || !from) return reply({ error: "Validation e-mail non configurée sur le serveur." }, 503);
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\\s+/i, "");
  if (!token) return reply({ error: "Connexion requise." }, 401);
  const authClient = createClient(url, anon, { global: { headers: { Authorization: "Bearer " + token } } });
  const { data: { user }, error: authError } = await authClient.auth.getUser(token);
  if (authError || !user) return reply({ error: "Session invalide. Reconnectez-vous." }, 401);
  const email = user.email?.trim().toLowerCase();
  if (!email) return reply({ error: "Ce compte ne possède pas d'adresse e-mail enregistrée." }, 400);
  const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
  let body: { action?: string; phone?: string; code?: string };
  try { body = await req.json(); } catch { return reply({ error: "Requête invalide." }, 400); }

  try {
    if (body.action === "start") {
      const phone = normalize(body.phone ?? "");
      const { data: used, error: usedError } = await admin.from("users").select("id").eq("registered_phone", phone).not("phone_verified_at", "is", null).limit(1);
      if (usedError) throw usedError;
      if (used?.length) return reply({ error: "Ce numéro est déjà enregistré sur BIIC CHAT." }, 409);
      const { data: prior, error: priorError } = await admin.from("phone_registration_codes").select("last_sent_at").eq("user_id", user.id).maybeSingle();
      if (priorError) throw priorError;
      if (prior?.last_sent_at && Date.now() - new Date(prior.last_sent_at).getTime() < 60_000) return reply({ error: "Attendez une minute avant de demander un nouveau code." }, 429);
      const random = new Uint32Array(1); crypto.getRandomValues(random);
      const code = String(random[0] % 1_000_000).padStart(6, "0");
      const codeHash = await hash(user.id + ":" + phone + ":" + code + ":" + serviceKey);
      const now = new Date();
      const { error: saveError } = await admin.from("phone_registration_codes").upsert({
        user_id: user.id, phone, code_hash: codeHash,
        expires_at: new Date(now.getTime() + 600_000).toISOString(),
        attempts: 0, last_sent_at: now.toISOString(), consumed_at: null,
      });
      if (saveError) throw saveError;
      const sent = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: "Bearer " + resendKey, "Content-Type": "application/json" },
        body: JSON.stringify({
          from, to: [email], subject: "Code de validation de votre numéro — BIIC CHAT",
          text: "Votre code de validation BIIC CHAT est : " + code + "\\nCe code expire dans 10 minutes. Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.",
          html: "<p>Votre code de validation BIIC CHAT est :</p><p style='font-size:28px;font-weight:bold;letter-spacing:6px'>" + code + "</p><p>Ce code expire dans 10 minutes. Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.</p>",
        }),
      });
      if (!sent.ok) { console.error("Resend failure", sent.status, await sent.text()); return reply({ error: "L'e-mail n'a pas pu être envoyé. Réessayez plus tard." }, 502); }
      return reply({ message: "Code envoyé à l'adresse e-mail associée à votre compte.", emailHint: email.replace(/^(.).+(@.*)$/, "$1***$2") });
    }

    if (body.action === "verify") {
      const code = (body.code ?? "").trim();
      if (!/^\\d{6}$/.test(code)) return reply({ error: "Saisissez le code à 6 chiffres reçu par e-mail." }, 400);
      const { data: challenge, error } = await admin.from("phone_registration_codes").select("phone,code_hash,expires_at,attempts,consumed_at").eq("user_id", user.id).maybeSingle();
      if (error) throw error;
      if (!challenge || challenge.consumed_at || new Date(challenge.expires_at).getTime() < Date.now()) return reply({ error: "Code expiré. Demandez un nouveau code." }, 400);
      if (challenge.attempts >= 5) return reply({ error: "Trop de tentatives. Demandez un nouveau code." }, 429);
      const supplied = await hash(user.id + ":" + challenge.phone + ":" + code + ":" + serviceKey);
      if (supplied !== challenge.code_hash) {
        await admin.from("phone_registration_codes").update({ attempts: challenge.attempts + 1 }).eq("user_id", user.id);
        return reply({ error: "Code incorrect." }, 400);
      }
      const { data: conflict, error: conflictError } = await admin.from("users").select("id").eq("registered_phone", challenge.phone).not("phone_verified_at", "is", null).limit(1);
      if (conflictError) throw conflictError;
      if (conflict?.some((row) => row.id !== user.id)) return reply({ error: "Ce numéro est déjà enregistré sur BIIC CHAT." }, 409);
      const { error: updateError } = await admin.from("users").update({ registered_phone: challenge.phone, phone_verified_at: new Date().toISOString() }).eq("id", user.id);
      if (updateError) throw updateError;
      await admin.from("phone_registration_codes").update({ consumed_at: new Date().toISOString() }).eq("user_id", user.id);
      return reply({ message: "Numéro enregistré et validé. Vous pouvez maintenant être trouvé sur BIIC CHAT.", phone: challenge.phone });
    }
    return reply({ error: "Action invalide." }, 400);
  } catch (error) {
    console.error("phone-registration failure", error);
    return reply({ error: error instanceof Error ? error.message : "Une erreur est survenue." }, 400);
  }
});
