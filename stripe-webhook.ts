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
  const meta = obj?.metadata ?? {};

  /* Qui a été payé ? Trois façons de le dire, de la plus précise à la plus
     ancienne :

       preparation=<id>  la préparation : un seul compteur, celui de sa ligne
       session=<id>      une séance vendue à l'unité : son compteur à elle
       evenement=<nom>   l'ancienne façon, conservée pour les liens de
                         paiement déjà en circulation

     Sans aucune de ces métadonnées, on retombe sur incr_inscrits_pack(),
     qui incrémente TOUTES les séances portant un lien pack. C'était le
     comportement d'origine ; il ne vaut que tant qu'une seule préparation
     est en vente. Renseigne « preparation » sur tes liens Stripe et ce
     repli ne servira plus. */
  const preparation = meta.preparation || null;
  const session = meta.session || null;
  const evenement = meta.evenement || null;

  async function compter(sens: "incr" | "decr") {
    if (preparation) return rpc(sens + "_inscrits_preparation", { p_id: preparation });
    if (session) return rpc(sens + "_inscrits_session", { p_id: session });
    if (evenement) return rpc(sens + "_inscrits_evenement", { p_evenement: evenement });
    return rpc(sens + "_inscrits_pack", {});
  }

  // Paiement réussi → +1 inscrit (uniquement checkout.session.completed pour ne jamais compter deux fois)
  if (event.type === "checkout.session.completed") {
    await compter("incr");
  } // Remboursement TOTAL → -1 inscrit (la place se rouvre)
  else if (event.type === "charge.refunded") {
    const rembTotal = (obj.amount_refunded ?? 0) >= (obj.amount ?? 0);
    /* Attention : l'objet reçu ici est le DÉBIT, pas la session de paiement.
       Rien ne garantit que les métadonnées du lien l'aient suivi. Si elles
       manquent, on retombe sur le repli — d'où l'intérêt de tester un
       remboursement et de vérifier quel compteur bouge. */
    if (rembTotal) await compter("decr");
  }

  return new Response("ok", { status: 200 });
});
