// ═══════════════════════════════════════════════════════════════════════
//  Fonction Edge Supabase : « stripe-webhook »  (sans dépendance externe)
//  Reçoit les paiements Stripe → vérifie la signature → +1 / -1 inscrit.
//
//  À déployer dans Supabase → Edge Functions → nom « stripe-webhook ».
//  IMPORTANT : désactive « Verify JWT » pour cette fonction (Stripe n'envoie
//  pas de jeton Supabase). Un seul secret à définir : STRIPE_WEBHOOK_SECRET.
// ═══════════════════════════════════════════════════════════════════════

const WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Appel de l'API REST Supabase avec la clé service (fournie automatiquement).
function rest(path: string, init: RequestInit = {}): Promise<Response> {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      "apikey": SERVICE_KEY,
      "Authorization": `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

async function rpc(fn: string, args: Record<string, unknown>): Promise<void> {
  await rest(`rpc/${fn}`, { method: "POST", body: JSON.stringify(args) });
}

// Vérifie la signature Stripe (HMAC-SHA256) sans dépendre du SDK Stripe.
async function verifierStripe(rawBody: string, sigHeader: string): Promise<any> {
  const parts: Record<string, string> = {};
  for (const p of sigHeader.split(",")) {
    const [k, v] = p.split("=");
    if (k && v) parts[k.trim()] = v.trim();
  }
  const t = parts["t"];
  const v1 = parts["v1"];
  if (!t || !v1) throw new Error("En-tête de signature invalide");

  const signedPayload = `${t}.${rawBody}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(signedPayload));
  const expected = [...new Uint8Array(sigBuf)].map((b) => b.toString(16).padStart(2, "0")).join("");

  if (expected.length !== v1.length) throw new Error("Signature non concordante");
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ v1.charCodeAt(i);
  if (diff !== 0) throw new Error("Signature non concordante");

  return JSON.parse(rawBody);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const sig = req.headers.get("stripe-signature") ?? "";
  const rawBody = await req.text();

  let event: any;
  try {
    event = await verifierStripe(rawBody, sig);
  } catch (e) {
    return new Response("Signature refusée : " + (e as Error).message, { status: 400 });
  }

  // Anti-doublon : on n'enregistre chaque événement Stripe qu'une fois
  const ins = await rest("stripe_events", { method: "POST", body: JSON.stringify({ id: event.id }) });
  if (ins.status === 409) return new Response("déjà traité", { status: 200 });
  if (!ins.ok) return new Response("Erreur base : " + (await ins.text()), { status: 500 });

  const obj = event.data?.object ?? {};
  const evenement = obj?.metadata?.evenement || null;

  // Paiement réussi → +1 inscrit (uniquement checkout.session.completed pour ne jamais compter deux fois)
  if (event.type === "checkout.session.completed") {
    if (evenement) await rpc("incr_inscrits_evenement", { p_evenement: evenement });
    else await rpc("incr_inscrits_pack", {});
  } // Remboursement TOTAL → -1 inscrit (la place se rouvre)
  else if (event.type === "charge.refunded") {
    const rembTotal = (obj.amount_refunded ?? 0) >= (obj.amount ?? 0);
    if (rembTotal) {
      if (evenement) await rpc("decr_inscrits_evenement", { p_evenement: evenement });
      else await rpc("decr_inscrits_pack", {});
    }
  }

  return new Response("ok", { status: 200 });
});
