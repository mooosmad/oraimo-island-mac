# Historique

## 0.3.1 — 31 octobre 2026

- La grande popup se replie en compact quand les Oraimo deviennent la sortie audio, même si elle est encore visible.
- Une courte présentation de la photo reste visible si l’audio est déjà sélectionné à la connexion.
- Statut compact plus étroit, texte centré et espaces équilibrés entre icône et batterie.
- Recentrage du panneau conservé lors du passage entre les deux tailles.
- README illustré avec les états de connexion, audio, déconnexion et batterie faible, et distinction explicite entre sortie audio et détection dans les oreilles.

## 0.3.0 — 31 octobre 2026

- Popup épurée : nom du produit affiché une seule fois, statut court, photo centrale et batterie sans doublon.
- Fermeture discrète et masquage automatique conservé.
- Recherche de nouvelles versions stables, proposition de téléchargement et vérification manuelle dans le menu.
- Désactivation des vérifications automatiques et possibilité d’ignorer une version.
- Aperçu de la nouvelle présentation et guide de mise à jour dans le README.

## 0.2.0 — 31 octobre 2026

- Reconnaissance de la **Watch 6 Nano (OSW-807N)**, icône de montre et sélection des appareils par adresse Bluetooth.
- Vraie icône d’application : l’ancienne `OraimoIsland.icns` n’était qu’un carré noir. Elle se régénère avec `scripts/make-icon.swift`.
- Reconnaissance des **oraimo SpaceBuds Neo** : photo du modèle, pictogramme d’écouteurs et photo personnalisable propre au modèle.
- Le rapport Bluetooth de macOS n’est plus lancé toutes les 30 s quand aucun Oraimo n’est connecté.
- L’alerte de batterie faible ne replie plus la popup de connexion et tient compte des écouteurs gauche/droite.
- Un nouveau relevé de batterie n’écrase plus le titre affiché (« Batterie faible », « Audio sur tes Oraimo »).
- Deux appareils portant le même nom ne partagent plus une lecture de batterie BLE.
- Un appareil choisi dans le menu puis déconnecté ne masque plus un autre Oraimo connecté ; un appareil désappairé rétablit la sélection automatique.
- Le message de déconnexion nomme l’appareil qui vient de partir.
- La popup reste collée en haut de l’écran quelle que soit la hauteur de son contenu.

## 0.1.0 — 30 octobre 2026

Première version publique macOS.

- Détection des Oraimo connectés et popups temporaires.
- Photos et icônes adaptées aux SpaceBuds Lite 2 et au BoomPop Pro.
- Mesures de batterie indépendantes et masquage des données absentes.
- App de barre des menus avec surveillance en arrière-plan.
- Binaire universel Apple Silicon / Intel, DMG et empreinte SHA-256.

Distribution de test signée ad hoc, non notarisée. macOS 14 minimum. Validation matérielle sur Apple Silicon ; Intel compilé mais pas encore testé matériellement.
