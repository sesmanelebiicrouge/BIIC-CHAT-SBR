import { Webhook } from "npm:standardwebhooks@1.0.0";

const ORANGE_TOKEN_URL = "https://api.orange.com/oauth/v3/token";
const ORANGE_SMS_BASE = "https://api.orange.com/smsmessaging/v1";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function required(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing server secret: ${name}`);
  return value;
}

async function getOrangeAccessToken(clientId: string, clientSecret: string) {
  const basic = btoa(`${clientId}:${clientSecret}`);
  const response = await fetch(ORANGE_TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Orange OAuth failed (HTTP ${response.status}): ${details.slice(0, 500)}`);
  }

  const data = await response.json();
  if (!data.access_token) throw new Error("Orange OAuth response did not contain an access token.");
  return data.access_token as string;
}

function normalizeIvoryCoastPhone(phone: string): string {
  const raw = phone.trim().replace(/[\s()-]/g, "");
  if (/^\+225\d{10}$/.test(raw)) return raw;
  if (/^00225\d{10}$/.test(raw)) return `+${raw.slice(2)}`;
  if (/^\d{10}$/.test(raw)) return `+225${raw}`;
  throw new Error("Invalid Côte d'Ivoire phone number.");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!hookSecret) return json({ error: "SMS hook is not configured." }, 500);

  try {
    const body = await req.text();
    const webhook = new Webhook(hookSecret);
    const event = webhook.verify(body, Object.fromEntries(req.headers.entries())) as {
      user?: { phone?: string };
      sms?: { otp?: string };
    };

    const phone = normalizeIvoryCoastPhone(event.user?.phone ?? "");
    const otp = String(event.sms?.otp ?? "").trim();

    if (!/^\d{6}$/.test(otp)) {
      throw new Error("Supabase did not provide a valid 6-digit OTP.");
    }

    const clientId = required("ORANGE_SMS_CLIENT_ID");
    const clientSecret = required("ORANGE_SMS_CLIENT_SECRET");
    const sender = Deno.env.get("ORANGE_SMS_SENDER")?.trim() || "tel:+2250000";

    const token = await getOrangeAccessToken(clientId, clientSecret);
    const senderEncoded = encodeURIComponent(sender);
    const endpoint =
      `${ORANGE_SMS_BASE}/outbound/${senderEncoded}/requests?resource_type_parameter_management=SMS_OCB2`;

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        outboundSMSMessageRequest: {
          address: `tel:${phone}`,
          senderAddress: sender,
          outboundSMSTextMessage: {
            message: `BIIC CHAT : votre code de vérification est ${otp}. Ne le partagez avec personne.`,
          },
        },
      }),
    });

    if (!response.ok) {
      const details = await response.text();
      throw new Error(`Orange SMS failed (HTTP ${response.status}): ${details.slice(0, 500)}`);
    }

    return new Response(null, { status: 200 });
  } catch (error) {
    console.error("BIIC CHAT Orange SMS hook error:", error);
    return json({ error: "Unable to send authentication SMS." }, 500);
  }
});
