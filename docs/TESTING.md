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

## Popup simplifiée et mises à jour

- Vérifier la photo et le nom unique sur SpaceBuds, BoomPop et montre ; garder masqués les niveaux absents. Avec gauche/droite/boîtier, chaque valeur doit avoir son libellé.
- Vérifier les statuts de connexion, déconnexion, batterie faible et changement de sortie audio, puis leur disparition automatique (6 / 4 / 3 secondes selon l’événement). La croix doit fermer immédiatement la popup.
- Menu « Rechercher des mises à jour… » : avec la même version publiée, message « à jour » ; sans réseau, message d’échec. Le mode automatique doit rester silencieux en cas d’échec.
- Pour tester une vraie version plus récente sans publier de fausse release, compiler une copie temporaire avec un CFBundleShortVersionString inférieur à la release publique. Vérifier « Télécharger » (DMG du dépôt officiel), « Plus tard », « Ignorer cette version » et l’absence d’alertes automatiques répétées pour cette version. Une vérification manuelle doit pouvoir reproposer la version ignorée.
- Désactiver la vérification automatique dans le menu : aucune requête automatique au prochain lancement. La vérification manuelle doit fonctionner.
- La v0.2.0 ne possède pas ce mécanisme : ses utilisateurs doivent installer une première fois une version contenant cette fonction.

## Transition vers le compact (0.3.1)

- Connecter les Oraimo avec la sortie audio déjà sélectionnée : grande photo pendant au moins 1,8 s, repli en compact, puis disparition après 3 s.
- Connecter sans sélectionner leur sortie : grande popup pendant environ 6 s. Sélectionner ensuite les Oraimo comme sortie : compact pendant 3 s.
- Sélectionner la sortie audio pendant la grande popup : elle doit se replier sans créer une seconde fenêtre.
- Déconnecter pendant le délai de 1,8 s, fermer via la croix ou ouvrir manuellement un autre appareil : la transition en attente doit être annulée et ne pas réafficher l’ancien appareil.
- Vérifier le centrage du nom/statut sur les deux tailles, avec 100 %, sans batterie et lors de la déconnexion ; le compact ne doit pas conserver de batterie périmée à droite.
- Rappel : ces événements ne testent pas un capteur d’ouverture du boîtier ni de présence dans les oreilles.
