import { Webhook } from "npm:standardwebhooks@1.0.0";

type EmailEvent = {
  user?: { email?: string; new_email?: string; old_email?: string };
  email_data?: {
    email_action_type?: string;
    token?: string;
    token_hash?: string;
    redirect_to?: string;
    site_url?: string;
    token_new?: string;
    token_hash_new?: string;
    old_email?: string;
    old_phone?: string;
    provider?: string;
    factor_type?: string;
  };
};

type EmailTemplate = { subject: string; heading: string; description: string };

const OTP_TEMPLATES: Record<string, EmailTemplate> = {
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
  reauthentication: {
    subject: "Code de sécurité — BIIC CHAT",
    heading: "Vérification de sécurité",
    description: "Saisissez ce code dans BIIC CHAT pour confirmer votre identité.",
  },
  email: {
    subject: "Votre code de vérification — BIIC CHAT",
    heading: "Code de vérification",
    description: "Saisissez ce code dans BIIC CHAT pour terminer cette opération.",
  },
};

const NOTIFICATION_TEMPLATES: Record<string, EmailTemplate> = {
  password_changed_notification: {
    subject: "Mot de passe modifié — BIIC CHAT",
    heading: "Votre mot de passe a été modifié",
    description: "Le mot de passe de votre compte BIIC CHAT vient d'être modifié. Si vous n'êtes pas à l'origine de cette action, sécurisez votre compte.",
  },
  email_changed_notification: {
    subject: "Adresse e-mail modifiée — BIIC CHAT",
    heading: "Votre adresse e-mail a été modifiée",
    description: "L'adresse e-mail associée à votre compte BIIC CHAT vient d'être modifiée. Si vous n'êtes pas à l'origine de cette action, sécurisez votre compte.",
  },
  phone_changed_notification: {
    subject: "Numéro de téléphone modifié — BIIC CHAT",
    heading: "Votre numéro de téléphone a été modifié",
    description: "Le numéro de téléphone associé à votre compte BIIC CHAT vient d'être modifié. Si vous n'êtes pas à l'origine de cette action, sécurisez votre compte.",
  },
  identity_linked_notification: {
    subject: "Méthode de connexion ajoutée — BIIC CHAT",
    heading: "Une méthode de connexion a été ajoutée",
    description: "Une nouvelle méthode de connexion vient d'être associée à votre compte BIIC CHAT.",
  },
  identity_unlinked_notification: {
    subject: "Méthode de connexion retirée — BIIC CHAT",
    heading: "Une méthode de connexion a été retirée",
    description: "Une méthode de connexion vient d'être retirée de votre compte BIIC CHAT.",
  },
  mfa_factor_enrolled_notification: {
    subject: "Vérification en deux étapes activée — BIIC CHAT",
    heading: "Un facteur de sécurité a été ajouté",
    description: "Un facteur d'authentification multifacteur vient d'être ajouté à votre compte BIIC CHAT.",
  },
  mfa_factor_unenrolled_notification: {
    subject: "Vérification en deux étapes modifiée — BIIC CHAT",
    heading: "Un facteur de sécurité a été retiré",
    description: "Un facteur d'authentification multifacteur vient d'être retiré de votre compte BIIC CHAT.",
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
  const entities: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  };
  return value.replace(/[&<>"']/g, (character) => entities[character] ?? character);
}

function validEmail(value: string | undefined): value is string {
  return !!value && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function validOtp(value: string | undefined): value is string {
  return !!value && /^\d{6}$/.test(value.trim());
}

async function sendEmail(to: string, template: EmailTemplate, token?: string): Promise<void> {
  const apiKey = required("RESEND_API_KEY");
  const from = required("BIIC_CHAT_FROM_EMAIL");
  const safeToken = token ? escapeHtml(token.trim()) : "";
  const tokenHtml = token
    ? `<p style="font-size:32px;font-weight:700;letter-spacing:8px;text-align:center;padding:18px;background:#f8f8f8;border-radius:10px">${safeToken}</p>`
    : "";
  const tokenText = token ? `\n\nVotre code : ${token.trim()}` : "";
  const html = `<!doctype html>
<html lang="fr"><body style="margin:0;background:#f5f5f5;font-family:Arial,sans-serif;color:#222">
  <div style="max-width:520px;margin:32px auto;padding:28px;background:#fff;border-radius:16px">
    <h2 style="margin-top:0;color:#d71920">BIIC CHAT</h2>
    <h3>${escapeHtml(template.heading)}</h3>
    <p>${escapeHtml(template.description)}</p>
    ${tokenHtml}
    ${token ? "<p>Ce code est temporaire. Ne le partagez avec personne.</p>" : ""}
    <p style="font-size:12px;color:#777">Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.</p>
  </div>
</body></html>`;
  const text = `BIIC CHAT — ${template.heading}\n\n${template.description}${tokenText}\n\nNe partagez jamais votre code de vérification.`;

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({ from, to: [to.trim()], subject: template.subject, html, text }),
  });

  if (!response.ok) {
    const details = await response.text();
    console.error("Resend delivery failed", response.status, details.slice(0, 500));
    throw new Error(`Email provider rejected the message (HTTP ${response.status}).`);
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const payload = await req.text();
    const event = await verifyWebhook(payload, Object.fromEntries(req.headers.entries()));
    const emailData = event.email_data;
    const action = emailData?.email_action_type ?? "";
    const email = (event.user?.email ?? "").trim().toLowerCase();
    const newEmail = (event.user?.new_email ?? "").trim().toLowerCase();

    if (!emailData || !action) throw new Error("Auth hook payload is missing email action data.");

    // Secure Email Change can generate one OTP for the old address and another for the new one.
    // Supabase's field naming is counterintuitive: token goes to the current address and
    // token_new goes to the new address when both tokens are present.
    if (action === "email_change") {
      if (validEmail(email) && validEmail(newEmail) &&
          validOtp(emailData.token) && validOtp(emailData.token_new)) {
        await sendEmail(email, {
          subject: "Confirmez le changement d'adresse — BIIC CHAT",
          heading: "Confirmez le changement d'adresse",
          description: "Saisissez ce code pour confirmer le changement demandé depuis votre adresse actuelle.",
        }, emailData.token);
        await sendEmail(newEmail, {
          subject: "Confirmez votre nouvelle adresse — BIIC CHAT",
          heading: "Confirmez votre nouvelle adresse e-mail",
          description: "Saisissez ce code pour confirmer cette nouvelle adresse e-mail.",
        }, emailData.token_new);
        return new Response("{}", { status: 200, headers: { "Content-Type": "application/json" } });
      }

      // With Secure Email Change disabled, Supabase sends one OTP to the new address.
      const newAddressToken = validOtp(emailData.token_new) ? emailData.token_new : emailData.token;
      if (!validEmail(newEmail) || !validOtp(newAddressToken)) {
        throw new Error("Email-change hook did not provide a valid destination or OTP.");
      }
      await sendEmail(newEmail, {
        subject: "Confirmez votre nouvelle adresse — BIIC CHAT",
        heading: "Confirmez votre nouvelle adresse e-mail",
        description: "Saisissez ce code pour confirmer cette nouvelle adresse e-mail.",
      }, newAddressToken);
      return new Response("{}", { status: 200, headers: { "Content-Type": "application/json" } });
    }

    const otpTemplate = OTP_TEMPLATES[action];
    if (otpTemplate) {
      // When linking an email to an anonymous account, Supabase may leave user.email empty.
      const destination = action === "email" && validEmail(newEmail) ? newEmail : email;
      if (!validEmail(destination)) throw new Error("Auth hook did not provide a valid destination email.");
      if (!validOtp(emailData.token)) throw new Error("Auth hook did not provide a six-digit email OTP.");
      await sendEmail(destination, otpTemplate, emailData.token);
      return new Response("{}", { status: 200, headers: { "Content-Type": "application/json" } });
    }

    const notificationTemplate = NOTIFICATION_TEMPLATES[action];
    if (notificationTemplate) {
      if (!validEmail(email)) throw new Error("Auth hook did not provide a valid destination email.");
      await sendEmail(email, notificationTemplate);
      return new Response("{}", { status: 200, headers: { "Content-Type": "application/json" } });
    }

    throw new Error(`Unsupported email action: ${action}`);
  } catch (error) {
    console.error("BIIC CHAT Send Email hook error:", error);
    return new Response(JSON.stringify({ error: "Unable to send authentication email." }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
