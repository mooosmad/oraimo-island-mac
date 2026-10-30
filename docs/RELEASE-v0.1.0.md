## Oraimo Island pour Mac — première version publique

Télécharge **Oraimo-Island-macOS-universal.dmg** dans les fichiers ci-dessous, ouvre-le, puis glisse **Oraimo Island.app** dans **Applications**. Aucun Xcode nécessaire pour l’utiliser.

- macOS **14+**, Mac **Apple Silicon ou Intel**.
- Popup de connexion ~6 secondes, puis icône de barre des menus.
- Message de déconnexion ~4 secondes, puis disparition de l’icône si aucun Oraimo n’est connecté.
- Visuels SpaceBuds Lite 2 et BoomPop Pro, batteries séparées, champs absents masqués.

### Premier lancement

Cette version de test est **signée ad hoc et non notarisée par Apple**. Si macOS bloque l’ouverture, suis la procédure **Réglages Système → Confidentialité et sécurité → Ouvrir quand même**, uniquement pour Oraimo Island téléchargée ici. Le README détaille cette étape et les autorisations Bluetooth.

### Limites

Le fonctionnement matériel a été observé sur Apple Silicon. La version Intel est compilée mais reste à tester sur une vraie machine. Un niveau de batterie dépend des informations exposées par l’appareil et macOS ; ANC, Concentration et état du couvercle ne sont pas pris en charge.

Guide complet : https://github.com/mooosmad/oraimo-island-mac#installer-en-2-minutes

`SHA256SUMS.txt` permet de vérifier le DMG avec `shasum -a 256 -c SHA256SUMS.txt`.
