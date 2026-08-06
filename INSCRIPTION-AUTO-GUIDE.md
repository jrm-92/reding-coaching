# Inscription automatique — mise en place

Objectif : quand quelqu'un paie le pack sur Stripe, le compteur `inscrits`
augmente **tout seul** ; et quand tu **rembourses** un client dans Stripe, la
place se **rouvre** automatiquement. Plus rien à faire à la main dans Supabase.

Il y a 5 étapes. Compte 15–20 min. Je peux faire les étapes Supabase avec toi
via Chrome ; les étapes Stripe se font de ton côté (je ne touche pas à ton compte
Stripe ni à tes clés secrètes).

---

## 1. Base de données (Supabase → SQL Editor)

Colle et exécute le contenu du fichier **`supabase-inscription-auto.sql`**.
Ça crée une table anti-doublon et deux fonctions d'incrément.

## 2. Créer la fonction (Supabase → Edge Functions)

- Menu **Edge Functions** → **Create a new function** → nom exact : `stripe-webhook`.
- Colle le contenu du fichier **`stripe-webhook.ts`**.
- **IMPORTANT** : désactive **« Verify JWT »** (ou « Enforce JWT ») pour cette
  fonction — sinon Stripe ne pourra pas l'appeler.
- **Deploy**.
- Note l'URL de la fonction, de la forme :
  `https://lacvhcuqkzsrojgcsjfj.supabase.co/functions/v1/stripe-webhook`

## 3. Créer le webhook côté Stripe

- Dans Stripe → **Développeurs → Webhooks → Ajouter un endpoint**.
- **URL** : colle l'URL de la fonction (étape 2).
- **Événements à écouter** : coche **`checkout.session.completed`** (paiement → +1)
  et **`charge.refunded`** (remboursement → −1, la place se rouvre).
- Valide. Puis ouvre l'endpoint créé et **révèle le « Signing secret »**
  (il commence par `whsec_...`). Copie-le.

## 4. Donner le secret à Supabase

- Supabase → **Edge Functions → (ta fonction) → Secrets** (ou Project Settings →
  Edge Functions → Secrets).
- Ajoute un secret :
  - **Nom** : `STRIPE_WEBHOOK_SECRET`
  - **Valeur** : le `whsec_...` copié à l'étape 3.

## 5. (Recommandé) Étiqueter le lien de paiement pack

Pour que ça reste juste même avec plusieurs packs à l'avenir :

- Dans Stripe, ouvre ton **lien de paiement** du pack → **Métadonnées**.
- Ajoute : clé `evenement` = valeur `Foulées Olympiques Colombienne 15/11/2026`
  (exactement le même texte que la colonne `evenement` dans Supabase).

Si tu sautes cette étape, ça marche quand même tant que tu n'as **qu'un seul
pack** (la fonction incrémente alors toutes les séances qui ont un lien pack).

---

## Tester

- Fais un **paiement test** (mode test Stripe, ou un vrai petit paiement que tu
  rembourseras) via le bouton « Acheter le pack ».
- Vérifie dans Supabase que `inscrits` est passé à 1 sur les séances du pack.
- Le site affichera alors « Il reste 7 places » au lieu de 8.
- Puis **rembourse** ce paiement dans Stripe → `inscrits` doit revenir à 0
  (la place se rouvre). Seul un remboursement **total** rouvre la place.

## Bon à savoir

- Le compteur est plafonné au nombre de `places` (pas de dépassement).
- Un même paiement n'est jamais compté deux fois (table anti-doublon).
- La fonction n'utilise que le secret `STRIPE_WEBHOOK_SECRET` ; la clé qui écrit
  dans la base est fournie automatiquement par Supabase, tu n'as rien à coller.
