-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Trois tables, trois rôles
--  À coller dans Supabase → SQL Editor → New query → Run.
--  Rejouable : il va de n'importe quel état vers le modèle final.
--
--  AVANT
--  Une préparation de douze séances occupait douze lignes de « sessions »
--  qui ne différaient que par la date, le titre et le sous-titre. Le prix,
--  le lien Stripe, les places et le compteur y étaient recopiés. D'où une
--  saisie pénible, et surtout :
--
--      update sessions set inscrits = inscrits + 1
--       where stripe_pack is not null and stripe_pack <> '';
--
--  qui incrémentait TOUTES les lignes portant un lien pack. Deux
--  préparations en parallèle, et une inscription à l'une remplissait
--  aussi l'autre.
--
--  APRÈS — chaque table a un seul rôle :
--
--    preparations        le produit vendu : nom, prix, lien, places, et UN
--                        compteur d'inscrits
--    preparation_seances son programme : une ligne par séance, avec sa date,
--                        son horaire et son intitulé. Rien d'autre : ces
--                        séances ne se vendent pas séparément
--    sessions            les séances vendues à l'unité, et elles seules.
--                        Chacune garde son prix, son lien et son compteur
--
--  Plus rien n'est mélangé : on ouvre la table qui correspond à ce qu'on
--  fait.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 0) Colonnes que le site attend, au cas où elles manqueraient ────────
--     « ancv » est arrivée avec le bouton Chèques-Vacances ; si sa migration
--     n'a jamais été lancée, la table ne l'a pas et la suite échouerait.
--
--     « actif » est le cas le plus grave : la page interroge « sessions »
--     avec le filtre actif=eq.true, et cette requête-là n'est pas
--     facultative. Sans la colonne, PostgREST répond 400, la promesse est
--     rejetée et la page n'affiche RIEN — pas même les préparations.
alter table public.sessions add column if not exists ancv        text    default '';
alter table public.sessions add column if not exists duree_prepa text    default '';
alter table public.sessions add column if not exists actif       boolean default true;

-- ── 1) Les préparations ─────────────────────────────────────────────────
create table if not exists public.preparations (
  id           text primary key,   -- ex. 'chatou-2027' ; c'est lui qui ira dans Stripe
  evenement    text default '',    -- titre affiché, ex. "Course Chatou - Saint-Germain-en-Laye"
  duree_prepa  text default '',    -- sous-titre, ex. "Préparation 10k - 12 semaines"
  prix         text default '',    -- ex. "160 €"
  stripe       text default '',    -- lien de paiement Stripe
  ancv         text default '',    -- lien de paiement ANCV / Chèques-Vacances
  lieu         text default '',    -- la VILLE (sert à la météo)
  sous_lieu    text default '',    -- lieu précis
  lien_course  text default '',    -- page d'inscription à la course visée
  places       int  default 10,
  inscrits     int  default 0,     -- LE compteur : un seul, ici
  actif        boolean default true
);

-- ── 2) Le programme d'une préparation ───────────────────────────────────
--     Une ligne par séance. Elle ne porte que ce qui lui appartient : ni
--     prix, ni lien de paiement, ni compteur — tout cela vit sur la
--     préparation.
create table if not exists public.preparation_seances (
  id             text primary key,
  -- « on update cascade » : renommer l'identifiant d'une préparation
  -- entraîne ses séances avec lui, en une seule requête.
  preparation_id text not null references public.preparations(id)
                 on update cascade on delete cascade,
  date           date not null,
  heure          text not null,     -- ex. "09h30"
  duree          text default '1h15',
  titre          text default '',   -- ex. "Test VMA"
  sous_titre     text default '',   -- ex. "Détermination de la VMA"
  description    text default '',
  actif          boolean default true
);
create index if not exists preparation_seances_prep_idx on public.preparation_seances(preparation_id);

--     Table déjà créée sans « on update cascade » ? On refait le lien, sinon
--     renommer une préparation serait refusé par la clé étrangère.
do $$
begin
  if exists (select 1 from pg_constraint c
              where c.conname = 'preparation_seances_preparation_id_fkey'
                and c.confupdtype <> 'c') then
    alter table public.preparation_seances
      drop constraint preparation_seances_preparation_id_fkey;
    alter table public.preparation_seances
      add  constraint preparation_seances_preparation_id_fkey
      foreign key (preparation_id) references public.preparations(id)
      on update cascade on delete cascade;
  end if;
end $$;
create index if not exists preparation_seances_date_idx on public.preparation_seances(date);

-- ── 3) Sécurité : lecture publique, écriture interdite depuis le site ───
--     Même régime que « sessions » : un catalogue, aucune donnée personnelle.
alter table public.preparations       enable row level security;
alter table public.preparation_seances enable row level security;

drop policy if exists "Lecture publique des preparations" on public.preparations;
create policy "Lecture publique des preparations"
  on public.preparations for select to anon using (true);

drop policy if exists "Lecture publique du programme" on public.preparation_seances;
create policy "Lecture publique du programme"
  on public.preparation_seances for select to anon using (true);

-- ── 4) Reprise de l'existant ────────────────────────────────────────────
--     Chaque groupe de séances partageant un « evenement » ET un lien pack
--     devient une préparation. Identifiant dérivé du nom : minuscules,
--     accents aplatis, ponctuation en tirets. translate() plutôt que
--     unaccent(), qui demande une extension pas forcément activée.
insert into public.preparations (id, evenement, duree_prepa, prix, stripe, ancv, lieu, sous_lieu, lien_course, places, inscrits)
select
  trim(both '-' from left(regexp_replace(
    translate(lower(s.evenement),
              'àâäáãçéèêëíìîïñóòôöõúùûüýÿ',
              'aaaaaceeeeiiiinooooouuuuyy'),
    '[^a-z0-9]+', '-', 'g'), 60))              as id,
  s.evenement,
  max(s.duree_prepa)                           as duree_prepa,
  max(s.prix_pack)                             as prix,
  max(s.stripe_pack)                           as stripe,
  max(s.ancv)                                  as ancv,
  max(s.lieu)                                  as lieu,
  max(s.sous_lieu)                             as sous_lieu,
  -- Selon l'ancienneté de la base, la colonne s'appelle « lien_course » ou
  -- « lien_cours ». to_jsonb() lit la ligne comme un objet : une clé absente
  -- vaut NULL au lieu de faire échouer la requête.
  max(coalesce(to_jsonb(s) ->> 'lien_course',
               to_jsonb(s) ->> 'lien_cours'))  as lien_course,
  -- Les places étaient recopiées sur chaque ligne : on prend la plus grande,
  -- et le compteur le plus avancé — c'est déjà ainsi que la page lisait
  -- « inscrits » (le maximum du groupe).
  coalesce(max(s.places), 10)                  as places,
  coalesce(max(s.inscrits), 0)                 as inscrits
from public.sessions s
where coalesce(s.stripe_pack, '') <> ''
  and coalesce(s.evenement, '')   <> ''
group by s.evenement
on conflict (id) do nothing;

-- ── 5) Les séances du programme quittent « sessions » ───────────────────
--     Deux origines possibles, selon l'état de départ :
--       · une base déjà passée par la version à deux tables porte la
--         colonne « preparation_id » sur ses séances ;
--       · une base d'origine ne l'a pas : on retrouve la préparation par
--         le nom de l'événement.
--     Le bloc est dynamique parce que la colonne peut ne pas exister —
--     une requête qui la nomme en dur échouerait à l'analyse, avant même
--     de s'exécuter.
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema='public' and table_name='sessions'
                and column_name='preparation_id') then
    execute $x$
      insert into public.preparation_seances (id, preparation_id, date, heure, duree, titre, sous_titre, description, actif)
      select s.id, s.preparation_id, s.date, s.heure,
             coalesce(nullif(s.duree,''),'1h15'),
             coalesce(s.titre,''), coalesce(s.sous_titre,''),
             coalesce(s.description,''), coalesce(s.actif, true)
        from public.sessions s
       where s.preparation_id is not null
      on conflict (id) do nothing
    $x$;
    execute 'delete from public.sessions s where s.preparation_id is not null';
    -- La colonne n'a plus d'objet : « sessions » ne contient plus que des
    -- séances à l'unité.
    execute 'alter table public.sessions drop column preparation_id';
  end if;
end $$;

insert into public.preparation_seances (id, preparation_id, date, heure, duree, titre, sous_titre, description, actif)
select s.id, p.id, s.date, s.heure,
       coalesce(nullif(s.duree,''),'1h15'),
       coalesce(s.titre,''), coalesce(s.sous_titre,''),
       coalesce(s.description,''), coalesce(s.actif, true)
  from public.sessions s
  join public.preparations p on p.evenement = s.evenement
 where coalesce(s.stripe_pack,'') <> ''
on conflict (id) do nothing;

delete from public.sessions s
 using public.preparations p
 where p.evenement = s.evenement
   and coalesce(s.stripe_pack,'') <> '';

-- ── 6) Le comptage, enfin ciblé ─────────────────────────────────────────
--     « pg_temp » est écrit EN DERNIER dans le search_path, à dessein. Sans
--     lui, PostgreSQL fouille quand même le schéma temporaire — et le fouille
--     en PREMIER. Or n'importe qui peut y créer une table. Une requête non
--     qualifiée irait alors la lire à la place de la vraie. Les requêtes
--     ci-dessous nomment « public.preparations », donc elles ne tombaient pas
--     dans le piège ; le jour où l'une perdrait son préfixe, elle y tomberait.
--     C'est la convention posée par securite-lot1.sql sur les quatre fonctions
--     de la génération précédente.
create or replace function public.incr_inscrits_preparation(p_id text)
returns void language sql security definer set search_path = public, pg_temp as $$
  update public.preparations set inscrits = least(places, inscrits + 1) where id = p_id;
$$;

create or replace function public.decr_inscrits_preparation(p_id text)
returns void language sql security definer set search_path = public, pg_temp as $$
  update public.preparations set inscrits = greatest(0, inscrits - 1) where id = p_id;
$$;

create or replace function public.incr_inscrits_session(p_id text)
returns void language sql security definer set search_path = public, pg_temp as $$
  update public.sessions set inscrits = least(places, inscrits + 1) where id = p_id;
$$;

create or replace function public.decr_inscrits_session(p_id text)
returns void language sql security definer set search_path = public, pg_temp as $$
  update public.sessions set inscrits = greatest(0, inscrits - 1) where id = p_id;
$$;

-- Ces fonctions écrivent : seul le webhook, qui porte la clé service, les
-- appelle. Surtout pas « anon », qui pourrait sinon afficher toutes les
-- séances comme complètes depuis la barre d'adresse.
revoke all on function public.incr_inscrits_preparation(text) from public, anon, authenticated;
revoke all on function public.decr_inscrits_preparation(text) from public, anon, authenticated;
revoke all on function public.incr_inscrits_session(text)     from public, anon, authenticated;
revoke all on function public.decr_inscrits_session(text)     from public, anon, authenticated;
grant execute on function public.incr_inscrits_preparation(text) to service_role;
grant execute on function public.decr_inscrits_preparation(text) to service_role;
grant execute on function public.incr_inscrits_session(text)     to service_role;
grant execute on function public.decr_inscrits_session(text)     to service_role;

-- ── 7) L'identifiant doit rester utilisable comme référence de paiement ─
--     La page accroche l'identifiant à l'URL du lien Stripe, sous
--     « client_reference_id », qui n'accepte que lettres, chiffres, tiret et
--     souligné. Un identifiant contenant un espace ou un accent partirait
--     donc transformé, ne correspondrait plus à aucune ligne, et le compteur
--     resterait immobile SANS le moindre message d'erreur.
--
--     Mieux vaut une erreur à l'insertion, tout de suite, qu'un compteur
--     faux découvert trois semaines plus tard. Si des identifiants déjà en
--     base ne respectent pas la règle, la contrainte n'est pas posée et ils
--     sont énumérés : à corriger avant de relancer.
do $$
declare fautifs text;
begin
  select string_agg(quote_literal(id), ', ') into fautifs
    from public.preparations where id !~ '^[A-Za-z0-9_-]+$';
  if fautifs is not null then
    raise warning 'preparations : identifiants à corriger avant de poser la contrainte → %', fautifs;
  else
    alter table public.preparations drop constraint if exists preparations_id_reference;
    alter table public.preparations add  constraint preparations_id_reference
      check (id ~ '^[A-Za-z0-9_-]+$');
  end if;

  select string_agg(quote_literal(id), ', ') into fautifs
    from public.sessions where id !~ '^[A-Za-z0-9_-]+$';
  if fautifs is not null then
    raise warning 'sessions : identifiants à corriger avant de poser la contrainte → %', fautifs;
  else
    alter table public.sessions drop constraint if exists sessions_id_reference;
    alter table public.sessions add  constraint sessions_id_reference
      check (id ~ '^[A-Za-z0-9_-]+$');
  end if;
end $$;

-- ── 8) Vérification ─────────────────────────────────────────────────────
--
--   select p.id, p.evenement, p.prix, p.places, p.inscrits,
--          count(ps.id) as seances
--     from public.preparations p
--     left join public.preparation_seances ps on ps.preparation_id = p.id
--    group by p.id, p.evenement, p.prix, p.places, p.inscrits
--    order by p.id;
--
--   select id, titre, date, prix_unitaire, places, inscrits
--     from public.sessions order by date;   -- uniquement les séances à l'unité
--
-- ── Au quotidien ────────────────────────────────────────────────────────
--
--   L'identifiant d'une préparation sert de référence de paiement : garde-le
--   court, en minuscules, sans espace ni accent — « marathon-paris-2028 ».
--   Deux préparations au même prix peuvent partager le même lien Stripe : la
--   page y accroche des références différentes, le comptage reste juste.
--
--   Ajouter une séance au programme :
--     insert into public.preparation_seances
--       (id, preparation_id, date, heure, duree, titre, sous_titre)
--     values ('S13','course-chatou-saint-germain-en-laye',
--             '2027-05-08','09h30','1h15','Spécifique','Rappel d''allure');
--
--   Créer une séance à l'unité :
--     insert into public.sessions
--       (id, evenement, titre, date, heure, lieu, prix_unitaire, stripe, places)
--     values ('U1','Séance découverte','Endurance','2027-02-15','19h00',
--             'Nanterre','8 €','https://buy.stripe.com/...', 12);
