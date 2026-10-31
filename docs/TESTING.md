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

## SpaceBuds Neo et corrections de sélection

- Diagnostic matériel du 31 octobre 2026 : SpaceBuds Neo connectés, type `Headset`, fabricant `0x05D6`, produit `0x000A`, firmware 2.4.0, `device_batteryLevelMain` à 100 %. Le BoomPop Pro annonce les mêmes identifiants : la reconnaissance repose donc sur le nom.
- Tests automatisés : nom avec suffixe et casse, rejet des variantes voisines, distinction Lite 2 / Neo, ressources distinctes ; choix de l’appareil (sélection manuelle, sortie audio, stabilité, déconnexion) ; refus d’une lecture BLE entre homonymes ; seuil de batterie faible sur le minimum gauche/droite/global, sans le boîtier.
- À valider physiquement : popup des SpaceBuds Neo à la connexion avec leur photo, import d’une photo, alerte de batterie faible pendant la popup de connexion.

## Contribution Watch 6 Nano — OSW-807N

- Tests automatisés : reconnaissance du nom avec suffixe et différences de casse ; rejet des modèles voisins ; pictogramme et textes de montre ; ressources photo distinctes ; batterie absente masquée ; zéro explicite accepté ; exclusion des appareils non-Oraimo et des relevés déconnectés ; séparation montre/casque.
- Diagnostic matériel du 30 octobre 2026 : Watch 6 Nano connectée au Mac, type `Watch`, fabricant `0x0642`, produit `0x0220`. Aucune batterie dans le rapport système. Ces identifiants ne sont pas utilisés seuls pour reconnaître le modèle, leur unicité n’étant pas établie.
- Vérifié sur le Mac avec la montre connectée : lancement de la version compilée, popup « Montre connectée », nom réel, pictogramme de montre et absence de champ batterie. Tests automatisés et compilation universelle arm64/x86_64 réussis.
- À valider physiquement : cycle connexion/déconnexion, coexistence avec un casque Oraimo, sélection par le menu, import/réinitialisation de la photo, et disponibilité éventuelle de batterie par les sources existantes.
- Les fixtures utilisent des adresses fictives. Aucun numéro de série ni adresse Bluetooth réelle n’est versionné.

## Mise à jour intégrée (0.4.0)

- La fenêtre native doit proposer une mise à jour, télécharger sans navigateur, vérifier l’archive puis afficher « Installer et relancer ».
- Tester le remplacement et le démarrage d’un **nouveau binaire distinct** dans une app isolée ; vérifier un marqueur écrit uniquement par le nouveau binaire. Le scénario a été exécuté localement avec un flux signé et une archive signée sur localhost, puis le build 5 a remplacé le build 4 et redémarré.
- Le test local autorise HTTP uniquement dans son bundle temporaire. L’app distribuée utilise exclusivement le flux HTTPS de production, exige sa signature et vérifie l’archive avant extraction.
- Le test de signature doit accepter l’archive intacte et refuser la même archive après modification. Même vérification pour un flux signé modifié.
- Vérifier les choix de report/annulation, la désactivation des vérifications automatiques et les erreurs réseau. Vérifier la disponibilité du Dock temporaire et du menu lorsqu’une mise à jour est proposée sans Oraimo connecté.
- `./scripts/verify-bundle.sh` vérifie les deux architectures, la signature du bundle, le lien Sparkle, la configuration de signature et la licence embarquée. La CI l’exécute avant de préparer les archives.
- Les versions 0.3.1 et antérieures n’ont pas d’installeur intégré : une installation manuelle de migration reste nécessaire.
- Les versions distribuées restent ad hoc ; le scénario Developer ID/notarisation et les remplacements sur des dossiers nécessitant une autorisation macOS doivent être validés séparément.

## Transition vers le compact (0.3.1)

- Connecter les Oraimo avec la sortie audio déjà sélectionnée : grande photo pendant au moins 1,8 s, repli en compact, puis disparition après 3 s.
- Connecter sans sélectionner leur sortie : grande popup pendant environ 6 s. Sélectionner ensuite les Oraimo comme sortie : compact pendant 3 s.
- Sélectionner la sortie audio pendant la grande popup : elle doit se replier sans créer une seconde fenêtre.
- Déconnecter pendant le délai de 1,8 s, fermer via la croix ou ouvrir manuellement un autre appareil : la transition en attente doit être annulée et ne pas réafficher l’ancien appareil.
- Vérifier le centrage du nom/statut sur les deux tailles, avec 100 %, sans batterie et lors de la déconnexion ; le compact ne doit pas conserver de batterie périmée à droite.
- Rappel : ces événements ne testent pas un capteur d’ouverture du boîtier ni de présence dans les oreilles.
