-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Inscription automatique (paiement Stripe → +1 inscrit)
--  À coller dans Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════════

-- 1) Table anti-doublon : mémorise les événements Stripe déjà traités
--    (Stripe peut renvoyer plusieurs fois le même paiement → on n'incrémente qu'une fois)
create table if not exists public.stripe_events (
  id          text primary key,
  created_at  timestamptz default now()
);
alter table public.stripe_events enable row level security;
-- Aucune policy => seule la fonction (clé service_role) peut y accéder.

-- 2) Incrément par ÉVÉNEMENT (si le lien Stripe porte la metadata « evenement »)
create or replace function public.incr_inscrits_evenement(p_evenement text)
returns void
language sql
security definer
as $$
  update public.sessions
     set inscrits = least(places, inscrits + 1)
   where evenement = p_evenement;
$$;

-- 3) Incrément « pack » de secours (si pas de metadata) : toutes les séances
--    ayant un lien de paiement pack. Suffit tant qu'il n'y a qu'un seul pack.
create or replace function public.incr_inscrits_pack()
returns void
language sql
security definer
as $$
  update public.sessions
     set inscrits = least(places, inscrits + 1)
   where stripe_pack is not null and stripe_pack <> '';
$$;

-- 4) Décrément par ÉVÉNEMENT (remboursement → la place se rouvre)
create or replace function public.decr_inscrits_evenement(p_evenement text)
returns void
language sql
security definer
as $$
  update public.sessions
     set inscrits = greatest(0, inscrits - 1)
   where evenement = p_evenement;
$$;

-- 5) Décrément « pack » de secours (remboursement, sans metadata)
create or replace function public.decr_inscrits_pack()
returns void
language sql
security definer
as $$
  update public.sessions
     set inscrits = greatest(0, inscrits - 1)
   where stripe_pack is not null and stripe_pack <> '';
$$;
