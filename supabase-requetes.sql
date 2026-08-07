-- ═══════════════════════════════════════════════════════════════════════
--  REDING RUNNING — Bibliothèque de requêtes SQL (table public.sessions)
--  Chaque requête agit sur TOUTES les lignes (pas de filtre).
--  Pour ne toucher qu'un seul événement, ajoute à la fin :
--      where evenement = 'Foulées Olympiques Colombienne 15/11/2026';
-- ═══════════════════════════════════════════════════════════════════════


-- ══════════════ EVENEMENT (titre du groupe) ══════════════
-- Vider :
update public.sessions set evenement = '';
-- Remplir :
update public.sessions set evenement = 'Foulées Olympiques Colombienne 15/11/2026';


-- ══════════════ TITRE (titre de la carte) ══════════════
-- Vider :
update public.sessions set titre = '';
-- Remplir :
update public.sessions set titre = 'Développement';


-- ══════════════ SOUS_TITRE (sous-titre de la carte) ══════════════
-- Vider :
update public.sessions set sous_titre = '';
-- Remplir :
update public.sessions set sous_titre = 'Séance mixte';


-- ══════════════ DUREE_PREPA (petit sous-titre sous le nom de l'événement) ══════════════
-- Vider :
update public.sessions set duree_prepa = '';
-- Remplir :
update public.sessions set duree_prepa = '12 semaines';


-- ══════════════ DATE  (⚠ propre à chaque séance : à éditer plutôt ligne par ligne) ══════════════
-- Vider (⚠ la ligne disparaîtra du site si la date est vide) :
--   -- impossible de mettre '' : la colonne date n'accepte pas de texte.
--   -- Pour "vider", passe par le Table Editor, ou mets une date bidon :
update public.sessions set date = '2026-01-01';
-- Remplir (met la même date partout — rarement utile) :
update public.sessions set date = '2026-08-22';


-- ══════════════ HEURE ══════════════
-- Vider :
update public.sessions set heure = '';
-- Remplir :
update public.sessions set heure = '10h00';


-- ══════════════ DUREE ══════════════
-- Vider :
update public.sessions set duree = '';
-- Remplir :
update public.sessions set duree = '1h15';


-- ══════════════ LIEU (la ville) ══════════════
-- Vider :
update public.sessions set lieu = '';
-- Remplir :
update public.sessions set lieu = 'Courbevoie';


-- ══════════════ SOUS_LIEU (lieu précis / point de RDV) ══════════════
-- Vider :
update public.sessions set sous_lieu = '';
-- Remplir :
update public.sessions set sous_lieu = 'Départ et Retour Fbg de l''Arche';


-- ══════════════ PRIX_UNITAIRE (prix par séance ; vide = vente en pack uniquement) ══════════════
-- Vider :
update public.sessions set prix_unitaire = '';
-- Remplir :
update public.sessions set prix_unitaire = '8 €';


-- ══════════════ PRIX_PACK (prix du pack ; rempli = mode pack) ══════════════
-- Vider :
update public.sessions set prix_pack = '';
-- Remplir :
update public.sessions set prix_pack = '130 €';


-- ══════════════ STRIPE (lien de paiement d'une séance individuelle) ══════════════
-- Vider :
update public.sessions set stripe = '';
-- Remplir :
update public.sessions set stripe = 'https://buy.stripe.com/XXXXXXXX';


-- ══════════════ STRIPE_PACK (lien de paiement du pack) ══════════════
-- Vider :
update public.sessions set stripe_pack = '';
-- Remplir :
update public.sessions set stripe_pack = 'https://buy.stripe.com/fZu6oI7IP4fvbfDh1s8bS02';


-- ══════════════ DESCRIPTION ══════════════
-- Vider :
update public.sessions set description = '';
-- Remplir :
update public.sessions set description = 'Texte de description...';


-- ══════════════ PLACES (capacité totale) ══════════════
-- Remettre à la valeur par défaut :
update public.sessions set places = 10;
-- Fixer une valeur (ex. pack limité à 8) :
update public.sessions set places = 8;


-- ══════════════ INSCRITS (nombre de personnes inscrites) ══════════════
-- Remettre à zéro :
update public.sessions set inscrits = 0;
-- Fixer une valeur :
update public.sessions set inscrits = 5;
-- Ajouter 1 (comme une inscription manuelle) :
update public.sessions set inscrits = least(places, inscrits + 1);
-- Retirer 1 (comme une annulation) :
update public.sessions set inscrits = greatest(0, inscrits - 1);


-- ══════════════ COLONNE id ══════════════
-- ⚠ Ne PAS remplir/vider en masse : chaque ligne doit avoir un id UNIQUE.
--   À gérer uniquement ligne par ligne dans le Table Editor.


-- ══════════════ REQUÊTE UTILE : voir tout le contenu ══════════════
select * from public.sessions order by date;
