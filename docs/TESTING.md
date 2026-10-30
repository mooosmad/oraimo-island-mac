# Vérifications de la version 0.1.0

## Exécuté avant publication

- Tests de lecture de pourcentages, espaces français, zéro explicite et valeurs invalides.
- Exclusion des données d’appareils déconnectés et séparation des mesures des deux modèles.
- Masquage des champs absents et distinction niveau global / gauche-droite.
- Choix d’icônes et de ressources propres au BoomPop et aux SpaceBuds.
- Compilation optimisée pour arm64 et x86_64, minimum macOS 14.0.
- Assemblage universel, validation de la signature ad hoc et du contenu du DMG.

## Observations matérielles pendant le développement

Les SpaceBuds Lite 2 et le BoomPop Pro ont été détectés sur un Mac Apple Silicon. Des niveaux globaux de batterie réels ont été affichés. Cela ne garantit pas qu’un niveau soit accessible en permanence ou sur tous les firmwares. Les niveaux séparés du boîtier et des écouteurs n’ont pas été confirmés sur ces modèles.

Le retrait temporisé de la popup et la visibilité de l’icône ont aussi été contrôlés avec des événements de connexion/déconnexion simulés, sans provoquer de déconnexion du matériel. Un nouvel affichage n’est pas masqué par la fin d’un ancien fondu.

## À valider sur d’autres machines

- Installation depuis un navigateur, avec quarantaine et autorisation individuelle de macOS.
- Premier refus puis autorisation Bluetooth.
- Cycle réel connexion → popup 6 s → icône ; déconnexion → message 4 s → disparition de l’icône si aucun Oraimo ne reste connecté.
- Mac Intel, macOS 14/15/26, autres écrans et différentes dispositions de moniteurs.
- Relevés de batterie basse, import et réinitialisation d’une photo personnalisée.

Les différences de firmware et de version de macOS peuvent affecter les sources de batterie privées. Une compilation universelle ne remplace pas ces essais matériels.

## Contribution Watch 6 Nano — OSW-807N

- Tests automatisés : reconnaissance du nom avec suffixe et différences de casse ; rejet des modèles voisins ; pictogramme et textes de montre ; ressources photo distinctes ; batterie absente masquée ; zéro explicite accepté ; exclusion des appareils non-Oraimo et des relevés déconnectés ; séparation montre/casque.
- Diagnostic matériel du 30 octobre 2026 : Watch 6 Nano connectée au Mac, type `Watch`, fabricant `0x0642`, produit `0x0220`. Aucune batterie dans le rapport système. Ces identifiants ne sont pas utilisés seuls pour reconnaître le modèle, leur unicité n’étant pas établie.
- Vérifié sur le Mac avec la montre connectée : lancement de la version compilée, popup « Montre connectée », nom réel, pictogramme de montre et absence de champ batterie. Tests automatisés et compilation universelle arm64/x86_64 réussis.
- À valider physiquement : cycle connexion/déconnexion, coexistence avec un casque Oraimo, sélection par le menu, import/réinitialisation de la photo, et disponibilité éventuelle de batterie par les sources existantes.
- Les fixtures utilisent des adresses fictives. Aucun numéro de série ni adresse Bluetooth réelle n’est versionné.
