-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Le recueil des manipulations courantes
--  Supabase → SQL Editor. Copie le bloc dont tu as besoin, adapte les
--  valeurs entre guillemets, lance.
--
--  ATTENTION — tes anciennes requêtes enregistrées (« changement prix »,
--  « Changement lien stripe », « Changer nom évènement »…) visent des
--  colonnes de « sessions » qui ne font plus foi depuis la séparation en
--  trois tables. Elles s'exécutent sans erreur et ne changent rien de
--  visible. Remplace-les par les blocs ci-dessous.
--
--  OÙ VIT QUOI
--    preparations         le produit : nom, prix, lien, places, compteur
--    preparation_seances  son programme : une ligne par séance
--    sessions             les séances vendues à l'unité, et elles seules
--
--  L'identifiant d'une préparation part dans le lien de paiement : il ne
--  doit contenir que lettres, chiffres, tirets et soulignés. La base
--  refuse le reste.
-- ═══════════════════════════════════════════════════════════════════════


-- ═══ 1. UNE PRÉPARATION ═════════════════════════════════════════════════

-- ── 1.1 La créer ───────────────────────────────────────────────────────
insert into public.preparations
  (id, evenement, duree_prepa, prix, stripe, ancv, lieu, sous_lieu, lien_course, places)
values
  ('marathon-paris-2028',                    -- identifiant, sert de référence de paiement
   'Marathon de Paris 12/04/2028',           -- titre affiché sur le site
   'Préparation marathon - 16 semaines',     -- sous-titre
   '240 €',
   'https://buy.stripe.com/xxxxxxxx',        -- lien de paiement
   '',                                       -- lien Chèques-Vacances, si tu en as un
   'Nanterre',                               -- la VILLE
   'Bords de Seine',                         -- le point de rendez-vous
   'https://www.schneiderelectricparismarathon.com',  -- page d'inscription à la course
   10);                                      -- places

-- ── 1.2 Changer le nom affiché ─────────────────────────────────────────
update public.preparations
   set evenement = 'Marathon de Paris 12/04/2028'
 where id = 'marathon-paris-2028';

-- ── 1.3 Changer le sous-titre ──────────────────────────────────────────
update public.preparations
   set duree_prepa = 'Préparation marathon - 18 semaines'
 where id = 'marathon-paris-2028';

-- ── 1.4 Changer le prix ────────────────────────────────────────────────
--     Le prix affiché sur le site. Le montant réellement encaissé est
--     celui du lien Stripe : pense à changer les deux, ou tes athlètes
--     liront 240 € et paieront autre chose.
update public.preparations
   set prix = '260 €'
 where id = 'marathon-paris-2028';

-- ── 1.5 Changer le lien de paiement ────────────────────────────────────
--     Colle l'URL nue, sans rien ajouter : la page y accroche elle-même la
--     référence qui fait compter la bonne préparation.
update public.preparations
   set stripe = 'https://buy.stripe.com/nouveau-lien'
 where id = 'marathon-paris-2028';

-- ── 1.6 Renseigner le lien Chèques-Vacances ────────────────────────────
--     Vide = le bouton ANCV ne s'affiche pas. C'est l'état par défaut.
update public.preparations
   set ancv = 'https://ancv.example/paiement'
 where id = 'marathon-paris-2028';

-- ── 1.7 Changer le lieu ────────────────────────────────────────────────
--     « lieu » est la ville, « sous_lieu » le point de rendez-vous précis.
update public.preparations
   set lieu = 'Le Vésinet', sous_lieu = 'Stade des Merlettes'
 where id = 'marathon-paris-2028';

-- ── 1.8 Changer le lien vers la course visée ───────────────────────────
update public.preparations
   set lien_course = 'https://www.exemple-course.fr/inscription'
 where id = 'marathon-paris-2028';

-- ── 1.9 Changer le nombre de places ────────────────────────────────────
update public.preparations
   set places = 12
 where id = 'marathon-paris-2028';

-- ── 1.10 Corriger le compteur d'inscrits ───────────────────────────────
--     Le webhook Stripe le tient à jour tout seul. On n'y touche que pour
--     rattraper une inscription encaissée hors ligne — un règlement en
--     Chèques-Vacances, par exemple, qui ne passe pas par Stripe.
update public.preparations set inscrits = inscrits + 1 where id = 'marathon-paris-2028';  -- +1
update public.preparations set inscrits = inscrits - 1 where id = 'marathon-paris-2028';  -- -1
update public.preparations set inscrits = 0            where id = 'marathon-paris-2028';  -- remise à zéro

-- ── 1.11 La masquer du site, ou la remettre ────────────────────────────
update public.preparations set actif = false where id = 'marathon-paris-2028';  -- masquée
update public.preparations set actif = true  where id = 'marathon-paris-2028';  -- visible

-- ═══ 2. LES SÉANCES D'UNE PRÉPARATION ═══════════════════════════════════

-- ── 2.1 Ajouter une séance ─────────────────────────────────────────────
insert into public.preparation_seances
  (id, preparation_id, date, heure, duree, titre, sous_titre)
values
  ('MP1', 'marathon-paris-2028', '2028-01-08', '09h30', '1h15',
   'Reprise', 'Préparation physique');

-- ── 2.2 Créer tout un programme hebdomadaire d'un coup ─────────────────
--     Seize séances, tous les samedis à partir du 8 janvier. Les titres
--     sont donnés dans l'ordre ; adapte la liste et le nombre.
--     « on conflict do nothing » : une séance dont l'identifiant existe
--     déjà est laissée telle quelle. Tu peux donc relancer ce bloc après
--     en avoir ajouté une à la main, sans tout casser.
insert into public.preparation_seances
  (id, preparation_id, date, heure, duree, titre, sous_titre)
select
  'MP' || g,
  'marathon-paris-2028',
  date '2028-01-08' + (g - 1) * 7,
  '09h30',
  '1h15',
  (array['Reprise','Test VMA','Développement','Développement',
         'Développement','Développement','Seuil','Seuil',
         'Spécifique','Spécifique','Spécifique','Sortie longue',
         'Sortie longue','Allégée','Affûtage','Déblocage'])[g],
  'Séance mixte'
from generate_series(1, 16) g
on conflict (id) do nothing;

-- ── 2.3 Changer la date d'une séance ───────────────────────────────────
update public.preparation_seances
   set date = '2028-01-15'
 where id = 'MP1';

-- ── 2.4 Décaler tout le programme d'une semaine ────────────────────────
--     Utile quand la course est reportée, ou quand tu démarres huit jours
--     plus tard. Mets « - 7 » pour avancer.
update public.preparation_seances
   set date = date + 7
 where preparation_id = 'marathon-paris-2028';

-- ── 2.5 Changer l'horaire ──────────────────────────────────────────────
update public.preparation_seances                    -- toutes les séances
   set heure = '10h00', duree = '1h30'
 where preparation_id = 'marathon-paris-2028';

update public.preparation_seances                    -- une seule
   set heure = '18h30'
 where id = 'MP1';

-- ── 2.6 Changer l'intitulé d'une séance ────────────────────────────────
update public.preparation_seances
   set titre = 'Test VMA', sous_titre = 'Détermination de la VMA'
 where id = 'MP1';

-- ── 2.7 Annuler une séance sans la perdre ──────────────────────────────
--     Elle disparaît du site, la préparation en annonce une de moins.
update public.preparation_seances set actif = false where id = 'MP1';
update public.preparation_seances set actif = true  where id = 'MP1';   -- la remettre

-- ═══ 3. LES SÉANCES À L'UNITÉ ═══════════════════════════════════════════
--     Elles vivent dans « sessions », ne se rattachent à rien, et gardent
--     chacune leur prix, leur lien et leur compteur.

-- ── 3.1 En créer une ───────────────────────────────────────────────────
insert into public.sessions
  (id, evenement, titre, sous_titre, date, heure, duree,
   lieu, sous_lieu, prix_unitaire, stripe, ancv, places)
values
  ('U10',                                    -- identifiant, sert de référence de paiement
   'Séance découverte',                      -- titre du bloc sur le site
   'Endurance', 'Tous niveaux',
   '2028-02-15', '19h00', '1h',
   'Nanterre', 'Bords de Seine',
   '8 €',
   'https://buy.stripe.com/xxxxxxxx',
   '',                                       -- lien Chèques-Vacances, si tu en as un
   12);

-- ── 3.2 Changer son prix, son lien, ses places ─────────────────────────
update public.sessions set prix_unitaire = '10 €'                      where id = 'U10';
update public.sessions set stripe = 'https://buy.stripe.com/autre'     where id = 'U10';
update public.sessions set ancv   = 'https://ancv.example/seance'      where id = 'U10';
update public.sessions set places = 15                                 where id = 'U10';

-- ── 3.3 Changer sa date, son horaire, son lieu ─────────────────────────
update public.sessions
   set date = '2028-02-22', heure = '19h30', duree = '1h15',
       lieu = 'Le Vésinet', sous_lieu = 'Stade des Merlettes'
 where id = 'U10';

-- ── 3.4 Corriger son compteur ──────────────────────────────────────────
update public.sessions set inscrits = inscrits + 1 where id = 'U10';
update public.sessions set inscrits = 0            where id = 'U10';

-- ── 3.5 La masquer ─────────────────────────────────────────────────────
update public.sessions set actif = false where id = 'U10';
update public.sessions set actif = true  where id = 'U10';


-- ═══ 3 bis. TOUT MASQUER D'UN COUP ══════════════════════════════════════
--     Vider la page des séances collectives sans rien effacer. On ne
--     touche pas à « preparation_seances » : le programme ne s'affiche
--     jamais sans sa prépa, donc masquer la prépa suffit — et la rallumer
--     ramène ses douze séances d'un seul geste.

-- ── 3bis.1 D'ABORD : note ce qui est allumé aujourd'hui ────────────────
--     Sans cette liste, tu ne sauras plus quoi rallumer : un « set actif
--     = true » sans where réveillerait aussi ce que tu avais masqué exprès.
select 'preparation' as table_, id, evenement from public.preparations where actif
union all
select 'session',           id, evenement from public.sessions      where actif
order by table_, id;

-- ── 3bis.2 Tout masquer ────────────────────────────────────────────────
update public.preparations set actif = false where actif;
update public.sessions      set actif = false where actif;

-- ── 3bis.3 Vérifier : les deux compteurs à 0 ───────────────────────────
select
  (select count(*) from public.preparations where actif) as prepas_visibles,
  (select count(*) from public.sessions      where actif) as seances_visibles;

-- ── 3bis.4 Rallumer — un id à la fois, depuis la liste de 3bis.1 ───────
-- update public.preparations set actif = true where id = 'marathon-paris-2028';
-- update public.sessions      set actif = true where id in ('U10','U11');


-- ═══ 4. VÉRIFIER ════════════════════════════════════════════════════════

-- ── 4.1 Vue d'ensemble des préparations ────────────────────────────────
select p.id, p.evenement, p.prix, p.places, p.inscrits,
       p.places - p.inscrits          as restantes,
       count(ps.id) filter (where ps.actif) as seances_actives,
       min(ps.date)                   as debut,
       max(ps.date)                   as fin,
       p.actif
  from public.preparations p
  left join public.preparation_seances ps on ps.preparation_id = p.id
 group by p.id
 order by p.id;

-- ── 4.2 Le programme d'une préparation, dans l'ordre ───────────────────
select id, date, heure, duree, titre, sous_titre, actif
  from public.preparation_seances
 where preparation_id = 'marathon-paris-2028'
 order by date;

-- ── 4.3 Les séances à l'unité ──────────────────────────────────────────
select id, evenement, titre, date, heure, prix_unitaire,
       places, inscrits, places - inscrits as restantes, actif
  from public.sessions
 order by date;

-- ── 4.4 Ce que le site affiche vraiment ────────────────────────────────
--     La page ne charge que ce qui est actif ET pas encore passé.
select 'préparation' as type, p.evenement as nom, min(ps.date) as prochaine
  from public.preparations p
  join public.preparation_seances ps on ps.preparation_id = p.id and ps.actif
 where p.actif and ps.date >= current_date
 group by p.evenement
union all
select 'à l''unité', s.titre, s.date
  from public.sessions s
 where s.actif and s.date >= current_date
 order by prochaine;

-- ── 4.5 Séances orphelines ─────────────────────────────────────────────
--     Rattachées à une préparation absente ou masquée : la page les écarte
--     plutôt que de les afficher sans prix. Normalement aucune ligne.
select ps.id, ps.preparation_id, ps.date
  from public.preparation_seances ps
  left join public.preparations p on p.id = ps.preparation_id and p.actif
 where p.id is null
 order by ps.date;

-- ── 4.6 L'état de la plomberie ─────────────────────────────────────────
--     Deux réglages qu'on ne voit nulle part dans les tables, et dont
--     dépend le reste. Tu n'as pas à les comprendre pour t'en servir : si
--     la requête répond les deux lignes attendues, tout va bien.
--
--     · « clé étrangère du programme » — elle dit si les séances suivent
--       automatiquement quand tu renommes une préparation. Sans elle, la
--       recette 5.1 n'échoue pas à moitié : PostgreSQL REFUSE carrément le
--       renommage, avec une erreur. Attendu : « CASCADE — conforme ».
--
--     · « search_path des 8 compteurs » — les huit fonctions qui ajoutent
--       ou retirent 1 à « inscrits » quand un paiement arrive. Elles
--       tournent avec les pleins pouvoirs sur la base, donc on leur impose
--       de chercher leurs tables dans « public », et dans le schéma
--       temporaire seulement EN DERNIER. Sans cette consigne, PostgreSQL
--       fouille quand même le schéma temporaire, et le fouille en PREMIER —
--       où n'importe qui peut poser une fausse table du même nom. Nos huit
--       fonctions nomment « public.preparations » en toutes lettres, donc
--       elles ne tombent pas dans le piège aujourd'hui ; la consigne est la
--       ceinture en plus des bretelles. Attendu : « 8 / 8 conformes ».
--
--     Quand la lancer : après avoir rejoué un vieux script, ou modifié une
--     fonction dans l'interface Supabase. C'est un contrôle de régression,
--     pas une routine — si tu ne touches à rien, rien ne bouge.
select 'clé étrangère du programme' as controle,
       coalesce((select case when confupdtype = 'c'
                             then 'CASCADE — conforme'
                             else 'PAS de cascade — à réparer' end
                   from pg_constraint
                  where conname = 'preparation_seances_preparation_id_fkey'),
                'contrainte introuvable') as verdict
union all
select 'search_path des 8 compteurs',
       (select count(*) filter (where proconfig @> array['search_path=public, pg_temp'])
               || ' / ' || count(*) || ' conformes'
          from pg_proc
         where pronamespace = 'public'::regnamespace
           and proname like '%\_inscrits\_%');
--     Si un verdict n'est pas celui attendu, le script qui répare dépend
--     de ce qui cloche — les huit compteurs ne viennent pas du même fichier :
--       · « PAS de cascade »  → relancer supabase-preparations.sql (ce dépôt).
--       · moins de 8 / 8      → les quatre compteurs _preparation et _session
--                               viennent de supabase-preparations.sql ;
--                               les quatre _evenement et _pack viennent de
--                               supabase/securite-lot1.sql, dans le dépôt
--                               REDLAB. Relancer celui qui correspond.
--     Pour voir lesquels sont en cause, les huit avec leur réglage :
--         select proname, coalesce(array_to_string(proconfig, ', '),
--                                  '(aucun réglage)') as search_path
--           from pg_proc
--          where pronamespace = 'public'::regnamespace
--            and proname like '%\_inscrits\_%'
--          order by proname;


-- ═══ 5. CE QUI NE SE DÉFAIT PAS ═════════════════════════════════════════
--     Regroupé ici à dessein : ces requêtes détruisent, et on ne tombe pas
--     dessus par accident en cherchant comment changer un prix.
--     Dans presque tous les cas, « actif = false » suffit : la chose
--     disparaît du site et reste en base.

-- ── 5.1 Renommer l'identifiant d'une préparation ───────────────────────
--     Les séances suivent toutes seules (« on update cascade »).
--
--     La référence de paiement, elle, n'est PAS gravée dans le lien : la
--     page lit l'identifiant en base et l'accroche à l'URL au moment du
--     clic (preparations.id → prepaId → ref → client_reference_id). Une
--     inscription faite DEPUIS LE SITE reste donc comptée après un
--     renommage, même par un athlète à qui tu avais donné l'adresse de la
--     page il y a des mois.
--
--     Le seul cas perdant est une URL qui porte DÉJÀ « client_reference_id » :
--     la page n'y touche pas, et elle continue de désigner l'ancien
--     identifiant. Cela arrive si tu as recopié le lien depuis la page pour
--     l'envoyer à la main, ou si la colonne « stripe » contient un lien
--     paramétré. Le second cas se vérifie :
--
--         select id, stripe from public.preparations
--          where stripe like '%client_reference_id%';
--
--     Aucune ligne, et aucun lien recopié à la main en circulation : tu peux
--     renommer sans rien perdre.
update public.preparations
   set id = 'marathon-paris-28'
 where id = 'marathon-paris-2028';

-- ── 5.2 Supprimer une séance du programme ──────────────────────────────
delete from public.preparation_seances where id = 'MP1';

-- ── 5.3 Supprimer une séance à l'unité ─────────────────────────────────
delete from public.sessions where id = 'U10';

-- ── 5.4 Supprimer une préparation ──────────────────────────────────────
--     TOUTES ses séances partent avec elle (« on delete cascade »).
--     Compte-les avant, pour savoir ce que tu effaces :
select count(*) as seances_qui_seront_supprimees
  from public.preparation_seances
 where preparation_id = 'marathon-paris-28';

delete from public.preparations where id = 'marathon-paris-28';
