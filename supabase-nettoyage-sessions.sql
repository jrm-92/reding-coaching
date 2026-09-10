-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Vider ce qui fait doublon sur les séances rattachées
--  À lancer APRÈS supabase-preparations.sql. Facultatif.
--
--  Depuis la séparation, une séance rattachée à une préparation ne porte
--  plus que ce qui lui appartient : sa date, son titre, son sous-titre,
--  son horaire. Le nom de l'événement, le prix, le lien de paiement, les
--  places et le compteur viennent de la préparation.
--
--  Les valeurs recopiées sur les douze lignes ne sont donc plus lues. Les
--  laisser ne casse rien, mais elles mentent : on finit par corriger un
--  prix sur une séance en croyant l'avoir changé partout. Ce script les
--  vide.
--
--  On VIDE, on ne SUPPRIME PAS les colonnes : une séance à l'unité s'en
--  sert toujours, et le retour en arrière reste possible.
-- ═══════════════════════════════════════════════════════════════════════

update public.sessions s
   set evenement   = '',      -- vient de preparations.evenement
       prix_pack   = '',      -- vient de preparations.prix
       stripe_pack = '',      -- vient de preparations.stripe
       duree_prepa = '',      -- vient de preparations.duree_prepa
       lieu        = '',      -- vient de preparations.lieu
       sous_lieu   = '',      -- vient de preparations.sous_lieu
       places      = null,    -- vient de preparations.places
       inscrits    = null     -- LE compteur est celui de la préparation
 where s.preparation_id is not null;

-- Ce qui reste sur une séance rattachée, et ce qu'on continue d'y saisir :
--
--   select id, preparation_id, date, heure, duree, titre, sous_titre, actif
--     from public.sessions
--    where preparation_id is not null
--    order by date;
--
-- Ajouter une séance à une préparation existante :
--
--   insert into public.sessions (id, preparation_id, date, heure, duree, titre, sous_titre)
--   values ('S13', 'course-chatou-saint-germain-en-laye',
--           '2027-05-08', '09h30', '1h15', 'Spécifique', 'Rappel d''allure');
--
-- Une séance vendue à l'unité, elle, ne se rattache à rien et garde tout :
--
--   insert into public.sessions (id, evenement, titre, date, heure, lieu,
--                                prix_unitaire, stripe, places, inscrits)
--   values ('U1', 'Séance découverte', 'Endurance', '2027-02-15', '19h00',
--           'Nanterre', '8 €', 'https://buy.stripe.com/...', 12, 0);
