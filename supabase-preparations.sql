-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Séparer la PRÉPARATION de ses SÉANCES
--  À coller dans Supabase → SQL Editor → New query → Run.
--  Le script est idempotent : le relancer ne casse rien.
--
--  POURQUOI
--  Une préparation de douze séances occupait douze lignes de « sessions »,
--  qui ne différaient que par la date, le titre et le sous-titre. Le prix
--  pack, le lien Stripe, les places et le compteur d'inscrits y étaient
--  recopiés à l'identique — d'où une saisie pénible, et surtout :
--
--      update sessions set inscrits = inscrits + 1
--       where stripe_pack is not null and stripe_pack <> '';
--
--  qui incrémentait TOUTES les lignes portant un lien pack. Tant qu'il n'y
--  a qu'une préparation en cours, ça passe. Deux préparations en parallèle,
--  et une inscription à l'une remplit aussi l'autre.
--
--  APRÈS
--  Une préparation = une ligne dans « preparations », avec un seul prix, un
--  seul lien de paiement, un seul compteur. Une séance = une ligne dans
--  « sessions » qui s'y rattache, et ne porte plus que ce qui lui est propre :
--  sa date, son titre, son sous-titre. Une séance sans rattachement reste
--  une séance à l'unité, avec son prix et son compteur à elle — c'est le
--  seul cas où plusieurs lignes se justifient.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 0) Colonnes que le site attend, au cas où elles manqueraient ────────
--     « ancv » est arrivée avec le bouton Chèques-Vacances ; si sa migration
--     n'a jamais été lancée, la table ne l'a pas et tout ce qui suit échoue.
--     « add column if not exists » ne coûte rien quand elle est déjà là.
alter table public.sessions add column if not exists ancv        text default '';
alter table public.sessions add column if not exists duree_prepa text default '';

-- ── 1) La table des préparations ────────────────────────────────────────
create table if not exists public.preparations (
  id           text primary key,   -- ex. 'chatou-2027' ; c'est lui qui ira dans Stripe
  evenement    text default '',    -- titre affiché, ex. "Course Chatou - Saint-Germain-en-Laye"
  duree_prepa  text default '',    -- sous-titre, ex. "Préparation 10k - 12 semaines"
  prix         text default '',    -- ex. "160 €"
  stripe       text default '',    -- lien de paiement Stripe de la préparation
  ancv         text default '',    -- lien de paiement ANCV / Chèques-Vacances
  lieu         text default '',    -- la VILLE (sert à la météo)
  sous_lieu    text default '',    -- lieu précis
  lien_course  text default '',    -- page d'inscription à la course visée
  places       int  default 8,
  inscrits     int  default 0,     -- LE compteur : un seul, ici
  actif        boolean default true
);

-- ── 2) Le rattachement d'une séance à sa préparation ────────────────────
alter table public.sessions
  add column if not exists preparation_id text references public.preparations(id) on delete set null;

create index if not exists sessions_preparation_id_idx on public.sessions(preparation_id);

-- ── 3) Sécurité : lecture publique, écriture interdite depuis le site ───
--     Même régime que « sessions » : le catalogue est public, il ne contient
--     aucune donnée personnelle.
alter table public.preparations enable row level security;

drop policy if exists "Lecture publique des preparations" on public.preparations;
create policy "Lecture publique des preparations"
  on public.preparations
  for select
  to anon
  using (true);

-- ── 4) Reprise de l'existant ────────────────────────────────────────────
--     Chaque groupe de séances partageant un « evenement » ET un lien pack
--     devient une préparation. L'identifiant est dérivé du nom de
--     l'événement, en minuscules sans accents ni ponctuation.
--     « on conflict do nothing » : relancer le script ne réécrit pas une
--     préparation que tu aurais entre-temps corrigée à la main.
insert into public.preparations (id, evenement, duree_prepa, prix, stripe, ancv, lieu, sous_lieu, lien_course, places, inscrits)
select
  -- Identifiant dérivé du nom : minuscules, accents aplatis, ponctuation en
  -- tirets. translate() plutôt que unaccent() — cette dernière demande une
  -- extension qui n'est pas forcément activée, et on ne veut pas d'un script
  -- qui échoue à la première ligne.
  trim(both '-' from left(regexp_replace(
    translate(lower(s.evenement),
              'àâäáãçéèêëíìîïñóòôöõúùûüýÿ',
              'aaaaaceeeeiiiinooooouuuuyy'),
    '[^a-z0-9]+', '-', 'g'), 60)) as id,
  s.evenement,
  max(s.duree_prepa)                                   as duree_prepa,
  max(s.prix_pack)                                     as prix,
  max(s.stripe_pack)                                   as stripe,
  max(s.ancv)                                          as ancv,
  max(s.lieu)                                          as lieu,
  max(s.sous_lieu)                                     as sous_lieu,
  -- Selon l'ancienneté de ta base, la colonne s'appelle « lien_course » ou
  -- « lien_cours ». to_jsonb() lit la ligne comme un objet : une clé absente
  -- vaut NULL au lieu de faire échouer la requête.
  max(coalesce(to_jsonb(s) ->> 'lien_course',
               to_jsonb(s) ->> 'lien_cours'))          as lien_course,
  -- Les places étaient recopiées sur chaque ligne : on prend la valeur la
  -- plus grande, et le compteur le plus avancé — c'est déjà ainsi que la
  -- page lisait « inscrits » (le maximum du groupe).
  coalesce(max(s.places), 8)                           as places,
  coalesce(max(s.inscrits), 0)                         as inscrits
from public.sessions s
where coalesce(s.stripe_pack, '') <> ''
  and coalesce(s.evenement, '')  <> ''
group by s.evenement
on conflict (id) do nothing;

-- Rattache les séances à la préparation ainsi créée.
update public.sessions s
   set preparation_id = p.id
  from public.preparations p
 where s.preparation_id is null
   and coalesce(s.stripe_pack, '') <> ''
   and s.evenement = p.evenement;

-- ── 5) Le comptage, enfin ciblé ─────────────────────────────────────────
--     Une inscription à une préparation ne touche que cette préparation.
create or replace function public.incr_inscrits_preparation(p_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.preparations
     set inscrits = least(places, inscrits + 1)
   where id = p_id;
$$;

create or replace function public.decr_inscrits_preparation(p_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.preparations
     set inscrits = greatest(0, inscrits - 1)
   where id = p_id;
$$;

--     Et pour une séance vendue à l'unité, son propre compteur.
create or replace function public.incr_inscrits_session(p_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.sessions
     set inscrits = least(places, inscrits + 1)
   where id = p_id;
$$;

create or replace function public.decr_inscrits_session(p_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.sessions
     set inscrits = greatest(0, inscrits - 1)
   where id = p_id;
$$;

-- Ces fonctions écrivent : seul le webhook, qui porte la clé service, les
-- appelle. Personne d'autre — surtout pas « anon », qui pourrait sinon
-- afficher toutes les séances comme complètes depuis la barre d'adresse.
revoke all on function public.incr_inscrits_preparation(text) from public, anon, authenticated;
revoke all on function public.decr_inscrits_preparation(text) from public, anon, authenticated;
revoke all on function public.incr_inscrits_session(text)     from public, anon, authenticated;
revoke all on function public.decr_inscrits_session(text)     from public, anon, authenticated;
grant execute on function public.incr_inscrits_preparation(text) to service_role;
grant execute on function public.decr_inscrits_preparation(text) to service_role;
grant execute on function public.incr_inscrits_session(text)     to service_role;
grant execute on function public.decr_inscrits_session(text)     to service_role;

-- ── 6) Vérification ─────────────────────────────────────────────────────
--     À lancer après coup pour voir ce qui a été créé et rattaché :
--
--   select p.id, p.evenement, p.prix, p.places, p.inscrits,
--          count(s.id) as seances
--     from public.preparations p
--     left join public.sessions s on s.preparation_id = p.id
--    group by p.id, p.evenement, p.prix, p.places, p.inscrits
--    order by p.id;
--
--     Les colonnes prix_pack / stripe_pack / duree_prepa de « sessions » ne
--     sont plus lues pour une séance rattachée. Elles restent en place : le
--     retour en arrière ne coûte rien tant qu'on ne les efface pas.
