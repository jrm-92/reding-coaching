-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Sessions collectives : mise en place Supabase
--  À coller dans Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════════════════

-- 1) La table des sessions
create table if not exists public.sessions (
  id            text primary key,
  evenement     text default '',   -- titre du groupe (ex. "Foulées Olympiques Colombienne 15/11/2026")
  titre         text default '',   -- ex. "Reprise", "VMA"
  sous_titre    text default '',   -- ex. "Préparation physique"
  date          date not null,
  heure         text not null,     -- ex. "10h00"
  duree         text default '1h', -- ex. "1h15"
  lieu          text default '',   -- la VILLE (sert à la météo), ex. "Courbevoie"
  sous_lieu     text default '',   -- lieu précis, ex. "Départ et Retour Fbg de l'Arche"
  prix_unitaire text default '',   -- vide si vente en pack uniquement
  prix_pack     text default '',   -- ex. "90 €" ; rempli => bouton pack unique
  stripe        text default '',   -- lien de paiement Stripe de la séance (optionnel)
  stripe_pack   text default '',   -- lien de paiement Stripe du pack (optionnel)
  description   text default '',
  places        int  default 10,
  inscrits      int  default 0
);

-- 2) Sécurité : lecture publique autorisée, écriture interdite depuis le site
alter table public.sessions enable row level security;

drop policy if exists "Lecture publique des sessions" on public.sessions;
create policy "Lecture publique des sessions"
  on public.sessions
  for select
  to anon
  using (true);

-- 3) Import de tes 13 sessions actuelles
insert into public.sessions
  (id, evenement, titre, sous_titre, date, heure, duree, lieu, sous_lieu, prix_pack)
values
  ('S1',  'Foulées Olympiques Colombienne 15/11/2026', 'Reprise',            'Préparation physique',   '2026-08-22', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S2',  'Foulées Olympiques Colombienne 15/11/2026', 'Reprise',            'Préparation physique',   '2026-08-29', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S3',  'Foulées Olympiques Colombienne 15/11/2026', 'Test VMA',           'Détermination de la VMA','2026-09-05', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S4',  'Foulées Olympiques Colombienne 15/11/2026', 'Développement',      'Séance mixte',           '2026-09-12', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S5',  'Foulées Olympiques Colombienne 15/11/2026', 'Développement',      'Séance mixte',           '2026-09-19', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S6',  'Foulées Olympiques Colombienne 15/11/2026', 'Développement',      'Séance mixte',           '2026-09-26', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S7',  'Foulées Olympiques Colombienne 15/11/2026', 'Développement',      'Séance mixte',           '2026-10-03', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S8',  'Foulées Olympiques Colombienne 15/11/2026', 'Développement',      'Séance mixte',           '2026-10-10', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S9',  'Foulées Olympiques Colombienne 15/11/2026', 'Spécifique',         'Spé 10k',                '2026-10-17', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S10', 'Foulées Olympiques Colombienne 15/11/2026', 'Spécifique',         'Spé 10k',                '2026-10-24', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S11', 'Foulées Olympiques Colombienne 15/11/2026', 'Spécifique',         'Spé 10k',                '2026-10-31', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S12', 'Foulées Olympiques Colombienne 15/11/2026', 'Spécifique',         'Spé 10k',                '2026-11-07', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €'),
  ('S13', 'Foulées Olympiques Colombienne 15/11/2026', 'Spécifique allégée', 'Rappel d''allure',       '2026-11-09', '10h00', '1h15', 'Courbevoie', 'Départ et Retour Fbg de l''Arche', '90 €')
on conflict (id) do update set
  evenement   = excluded.evenement,
  titre       = excluded.titre,
  sous_titre  = excluded.sous_titre,
  date        = excluded.date,
  heure       = excluded.heure,
  duree       = excluded.duree,
  lieu        = excluded.lieu,
  sous_lieu   = excluded.sous_lieu,
  prix_pack   = excluded.prix_pack;

-- Vérif rapide : doit renvoyer 13
select count(*) as nb_sessions from public.sessions;
