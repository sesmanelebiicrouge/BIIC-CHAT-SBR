import { Webhook } from "npm:standardwebhooks@1.0.0";

type EmailEvent = {
  user?: { email?: string; new_email?: string };
  email_data?: {
    email_action_type?: string;
    token?: string;
    token_hash?: string;
    redirect_to?: string;
    site_url?: string;
    token_new?: string;
    new_token?: string;
  };
};

const ACTION_LABELS: Record<string, { subject: string; heading: string; description: string }> = {
  signup: {
    subject: "Confirmez votre adresse e-mail — BIIC CHAT",
    heading: "Confirmez votre adresse e-mail",
    description: "Saisissez ce code dans BIIC CHAT pour terminer la création de votre compte.",
  },
  recovery: {
    subject: "Code de récupération — BIIC CHAT",
    heading: "Réinitialisation du mot de passe",
    description: "Saisissez ce code dans BIIC CHAT pour continuer la récupération de votre compte.",
  },
  magiclink: {
    subject: "Votre code de connexion — BIIC CHAT",
    heading: "Connexion à BIIC CHAT",
    description: "Saisissez ce code dans BIIC CHAT pour vous connecter.",
  },
  invite: {
    subject: "Invitation BIIC CHAT",
    heading: "Invitation BIIC CHAT",
    description: "Saisissez ce code si l'application vous le demande pour accepter l'invitation.",
  },
  email_change: {
    subject: "Confirmez votre adresse e-mail — BIIC CHAT",
    heading: "Confirmation de changement d'e-mail",
    description: "Saisissez ce code dans BIIC CHAT pour confirmer le changement d'adresse.",
  },
  email_change_new: {
    subject: "Confirmez votre nouvelle adresse e-mail — BIIC CHAT",
    heading: "Confirmation de la nouvelle adresse",
    description: "Saisissez ce code dans BIIC CHAT pour confirmer cette adresse.",
  },
  reauthentication: {
    subject: "Code de sécurité — BIIC CHAT",
    heading: "Vérification de sécurité",
    description: "Saisissez ce code dans BIIC CHAT pour confirmer votre identité.",
  },
};

function required(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing server secret: ${name}`);
  return value;
}

function getWebhookSecrets(): string[] {
  return required("SEND_EMAIL_HOOK_SECRET")
    .split("|")
    .map((value) => value.trim().replace(/^v1,whsec_/, ""))
    .filter(Boolean);
}

async function verifyWebhook(payload: string, headers: Record<string, string>): Promise<EmailEvent> {
  let lastError: unknown;
  for (const secret of getWebhookSecrets()) {
    try {
      return new Webhook(secret).verify(payload, headers) as EmailEvent;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error("Invalid Send Email hook signature.");
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[character] ?? character);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload = await req.text();
    const event = await verifyWebhook(payload, Object.fromEntries(req.headers.entries()));
    const email = (event.user?.email ?? "").trim().toLowerCase();
    const emailData = event.email_data;
    const action = emailData?.email_action_type ?? "";
    const token = String(emailData?.token ?? "").trim();

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new Error("Auth hook did not provide a valid destination email.");
    }
    if (!/^\d{6}$/.test(token)) {
      throw new Error("Auth hook did not provide a six-digit email OTP.");
    }

    const template = ACTION_LABELS[action];
    if (!template) {
      throw new Error(`Unsupported email action: ${action || "unknown"}`);
    }

    const apiKey = required("RESEND_API_KEY");
    const from = required("BIIC_CHAT_FROM_EMAIL");
    const safeToken = escapeHtml(token);
    const html = `<!doctype html>
<html lang="fr"><body style="margin:0;background:#f5f5f5;font-family:Arial,sans-serif;color:#222">
  <div style="max-width:520px;margin:32px auto;padding:28px;background:#fff;border-radius:16px">
    <h2 style="margin-top:0;color:#d71920">BIIC CHAT</h2>
    <h3>${escapeHtml(template.heading)}</h3>
    <p>${escapeHtml(template.description)}</p>
    <p style="font-size:32px;font-weight:700;letter-spacing:8px;text-align:center;padding:18px;background:#f8f8f8;border-radius:10px">${safeToken}</p>
    <p>Ce code est temporaire. Ne le partagez avec personne.</p>
    <p style="font-size:12px;color:#777">Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.</p>
  </div>
</body></html>`;
    const text = `BIIC CHAT — ${template.heading}\n\n${template.description}\n\nVotre code : ${token}\n\nNe partagez ce code avec personne. Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.`;

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        from,
        to: [email],
        subject: template.subject,
        html,
        text,
      }),
    });

    if (!response.ok) {
      const details = await response.text();
      console.error("Resend delivery failed", response.status, details.slice(0, 1000));
      return new Response(JSON.stringify({ error: "Email provider rejected the message." }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("BIIC CHAT Send Email hook error:", error);
    return new Response(JSON.stringify({ error: "Unable to send authentication email." }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
