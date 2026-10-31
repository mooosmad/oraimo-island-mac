# Historique

## À venir

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
