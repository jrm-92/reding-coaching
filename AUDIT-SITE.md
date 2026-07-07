# Audit complet — reding-running.fr
*Audit UX/UI, copywriting, conversion (CRO) et SEO — réalisé le 7 juillet 2026, en se mettant dans la peau d'un prospect cherchant un coach running.*

> **Note :** ce document est la version restaurée de l'audit initial. La plupart des recommandations ci-dessous ont depuis été appliquées (voir la section « État d'avancement » en fin de document).

**Verdict global :** le site est nettement au-dessus de la moyenne des coachs indépendants (vraie identité visuelle, formulaire intelligent, preuves réelles). Mais il vend des *caractéristiques* plutôt qu'une *transformation*, garde sa meilleure preuve sociale au mauvais endroit, et n'exploite jamais son meilleur argument de conversion : **l'entretien découverte gratuit et sans engagement n'est vendu nulle part** — le mot « gratuit » n'apparaît pas une seule fois sur la page.

---

## 1. Première impression (5 secondes)

**Ce qu'on comprend immédiatement :** un coach running, jeune, rapide (35'20" au 10K visible), avec deux offres. C'est déjà mieux que 80 % des sites de coachs. La photo de course avec dossard est un excellent choix : elle prouve que tu pratiques ce que tu vends.

**Ce qui ne fonctionne pas :**

- **La proposition de valeur est générique.** « Atteignez vos objectifs et progressez durablement avec un accompagnement sur-mesure » pourrait être signé par n'importe quel coach de n'importe quel sport.
- **« Courir encadré » (3ᵉ ligne du H1, en outline)** est un slogan flou qui dilue le titre.
- **Rupture de ton dès la première seconde :** le hero vouvoie alors que 100 % du reste du site tutoie.
- **Aucun CTA de conversion dans le hero.** Les deux cartes disent « En savoir plus » — c'est de la navigation, pas de la conversion.
- **Les 4 badges sont inégaux.** « Carte Pro » est le plus faible (obligation légale, pas un argument). « Diplôme CQP » sans expliciter = jargon.

---

## 2. Design et identité visuelle

**Points forts :** typographie unique (Barlow), style italique 900 uppercase cohérent et sportif, orange #FF6B35 bien tenu, cartes soignées, vraie direction artistique.

**Points faibles :**

1. **Trop de couleurs d'accent** (25+ hex distincts, cartes tarifaires « arc-en-ciel »).
2. **Aucune respiration entre les sections** (même dégradé navy→teal partout).
3. **Micro-typographie illisible** (labels 7,5–9 px).
4. **`text-align: justify`** sur les paragraphes.
5. **Effets datés** (glows pulsés multiples, ombres orange épaisses, effet « shine »).
6. **Icônes incohérentes** (SVG vs ✓ texte vs emoji 📍 vs flèches texte).
7. **Grille témoignages 3 colonnes avec 1 seule carte.**
8. **Dette technique** : ~40 % du CSS mort, classes cassées (`.seréel`, `.aprésentiel`), style.css orphelin.

---

## 3. Parcours utilisateur (UX)

1. 🔴 **Les témoignages étaient APRÈS le formulaire** — la preuve sociale arrivait après la demande.
2. **Doublon « Comment démarrer ? »** (carte 4 étapes + première question FAQ).
3. **FAQ absente de la nav.**
4. **Carte Leaflet** coupe le flux de vente.
5. **Lead « Suivi à distance » de 40+ mots.**
6. **CTA bien placés dans l'ensemble** (point fort).
7. **Points de sortie :** hero (value prop), après les prix (pas de réassurance à proximité), formulaire mobile.

---

## 4. Contenu et copywriting

**Problème de fond : des caractéristiques, pas des bénéfices.**

À développer : le *pourquoi* dans l'À propos, la justification du prix (70 €/mois vs 50-80 € la séance classique), les portraits de coureurs types.

**Fautes relevées :** « Pour  coureurs de tous niveaux » (double espace + « les » manquant), « pour coureur de tous niveaux », « Lieux d'entrainement défini ensemble » (+ balise `<p>` non fermée), « Améliorer mes chrono », vouvoiement/tutoiement mélangés, « Ils ont progressé » au pluriel avec 1 témoignage.

**Réassurance manquante :** nombre de coureurs accompagnés, avis Google, intitulé exact du diplôme, garantie.

---

## 5. Conversion

1. L'offre d'entrée réelle — **entretien découverte gratuit et sans engagement** — est enterrée dans l'étape 02.
2. Titre de section « **Formulaire** » : purement administratif.
3. Pas de preuve sociale avant le formulaire.
4. **Sticky CTA mobile absent** (CSS stylé mais élément HTML jamais ajouté).
5. hCaptcha = friction (acceptable).
6. **Aucun analytics** : pilotage à l'aveugle.

**CTA plus efficaces :** « Réserver mon appel découverte — gratuit », « Parlons de ton objectif », micro-texte « Sans engagement · Réponse sous 24h ».

---

## 6. Crédibilité

**Fonctionne :** record vérifiable (lien athle.fr), formation FFA, photo dossard, témoignage avec capture Strava, pages légales complètes.

**Manque :** volume de preuve (1 seul témoignage), avis Google, chiffres (« X coureurs accompagnés »), présence sociale (aucun lien Instagram/Strava), intitulé précis du diplôme.

---

## 7. Différenciation

Rien ne répond à « pourquoi Jérémy plutôt qu'un autre ? ». Tes vrais différenciateurs, jamais assemblés : **athlète compétiteur en activité**, **hybride distance + terrain en IdF/La Défense**, **70 €/mois sans engagement ni prélèvement**.

---

## 8. Mobile

**Points forts :** breakpoints nombreux et travaillés, ré-ordonnancement du hero, cibles 44px, carte non-draggable.

**Problèmes :** pas de sticky CTA, hero mobile très long, textes 8–10,5 px, formulaire long, poids (HTML 204 Ko dont ~40 % CSS mort, photo 329 Ko non responsive, 14 variantes de police, Leaflet non lazy).

---

## 9. SEO

**Bon niveau technique :** title, meta description, canonical, OG, JSON-LD LocalBusiness + Person, sitemap, robots, une seule H1.

**Limites :** site one-page = plafond de verre (→ pages dédiées), H1 sans géolocalisation, H2 faibles (« Formulaire », « Ils ont progressé »), meta keywords obsolète, images sans lazy/dimensions/WebP, fiche Google Business Profile à créer (levier local n°1).

---

## 10. Priorisation

### 🔴 Impact très élevé
1. Vendre l'entretien découverte gratuit partout (CTA hero + nav + prix)
2. Déplacer les témoignages avant le formulaire ✅
3. CTA de conversion dans le hero
4. Réécrire la value prop (athlète + local + sans engagement)
5. Sticky CTA mobile
6. Installer un analytics ✅ (GA4 + bannière consentement — ID à renseigner)
7. Collecter 2 témoignages supplémentaires
8. Fiche Google Business Profile + avis

### 🟠 Impact moyen
9. Renommer « Formulaire » ✅ (« Parlons de ton objectif »)
10. Corriger les fautes ✅
11. Tutoiement partout (hero remis en vouvoiement sur demande)
12. Puces en bénéfices (remises en formulation d'origine sur demande)
13. Unifier les couleurs des cartes tarifaires ✅
14. Alterner les fonds de section ✅
15. Justifier le prix (comparaison + garantie)
16. Optimiser le poids ✅ (WebP, fonts réduites, purge CSS, lazy Leaflet)
17. H1/H2 avec mots-clés locaux ✅ (H2 ; H1 remis d'origine sur demande)
18. Étoffer l'À propos ✅

### 🟢 Impact faible
19. Doublon FAQ « Comment démarrer »
20. FAQ dans la nav ✅
21. Supprimer meta keywords ✅
22. Scripts morts ✅
23. Emoji 📍 ✅
24. Justify → left ✅
25. Labels ≥ 10-11px ✅
26. Classes cassées + style.css ✅
27. Grille témoignages ✅
28. Titre section témoignages ✅ (« Ils ont atteint leur objectif »)

---

## Travaux réalisés depuis l'audit (au-delà de la liste)

- 2 pages SEO créées : `suivi-running-a-distance.html` et `coach-running-la-defense.html` (+ sitemap + maillage footer)
- Image Open Graph dédiée `og-image.jpg` (1200×630)
- Sécurisation : Content-Security-Policy sur les 3 pages, `rel="noopener"` complété
- GA4 avec bannière de consentement RGPD (remplacer `G-XXXXXXXXXX` par l'ID réel)
- Harmonisation graphique : formulaire orange, radius 50px, flèches SVG, animations calmées, hovers jaunes → orange
- 6 fichiers logo inutilisés supprimés (~470 Ko)

## Reste à faire (actions utilisateur)

1. Remplacer `G-XXXXXXXXXX` dans index.html par l'ID GA4 réel + mentionner GA dans la politique de confidentialité
2. Créer la fiche Google Business Profile et collecter des avis
3. Obtenir 2 témoignages supplémentaires
4. Vérifier « Enforce HTTPS » dans les settings GitHub Pages
5. Tester formulaire + captcha + carte après mise en ligne (CSP)
6. Soumettre le sitemap dans Google Search Console
7. Committer et pousser régulièrement
