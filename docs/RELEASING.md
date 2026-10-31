# Publier une version avec mise à jour intégrée

## Clé de signature

La clé privée Ed25519 de production reste dans le Trousseau macOS, compte `io.github.mooosmad.OraimoIsland`, via l’outil Sparkle `generate_keys`. Seule la clé publique est suivie dans `Resources/Info.plist`. Ne jamais générer une nouvelle clé pour une release courante, exporter la clé dans le dépôt ou signer une version avec une clé différente : les apps installées la rejetteraient. Prévoir une sauvegarde sécurisée du Trousseau pour éviter de perdre la clé.

Les contributions et la CI n’ont pas besoin de clé privée : elles compilent l’app et construisent le DMG et le ZIP, mais ne signent pas le flux de production.

## Préparer et vérifier

1. Augmenter `CFBundleShortVersionString` et `CFBundleVersion` (nombre strictement croissant), actualiser CHANGELOG et README.
2. Exécuter `./Tests/run.sh`, `./build.sh`, `./scripts/package-dmg.sh`, puis `./scripts/package-update.sh`.
3. Sur le Mac disposant de la clé : `./scripts/publish-appcast.py`. Le script signe l’archive ZIP puis le flux et vérifie les deux signatures. Il ne publie aucun fichier.
4. Créer une release GitHub avec le DMG, `SHA256SUMS.txt`, le ZIP de version, LICENSE et THIRD_PARTY_NOTICES.md. Vérifier le téléchargement du ZIP et ses sommes de contrôle. Le code du tag doit correspondre aux fichiers compilés.
5. **Après** la publication effective des fichiers de release, publier `dist/appcast.xml` à la racine de la branche `updates`, sans le modifier (signature intégrée). L’URL fixe est `https://raw.githubusercontent.com/mooosmad/oraimo-island-mac/updates/appcast.xml`.
6. Télécharger le flux public et vérifier sa signature avec `sign_update --account io.github.mooosmad.OraimoIsland --verify appcast.xml`. Vérifier que son enclosure pointe sur le ZIP publié, de même taille et signature. Ne jamais proposer une archive dont la release n’est pas encore publique.

Sparkle vérifie le flux signé et l’archive signée avant extraction. Une simple somme SHA-256 publiée au même endroit n’est pas utilisée comme preuve d’authenticité. Les builds ad hoc n’activent pas Hardened Runtime ; pour une future distribution Developer ID, `SIGNING_IDENTITY` permet de signer les composants imbriqués avant le bundle principal. Tester et notariser cette configuration séparément.

## Essais

Tester la fenêtre de mise à jour dans une copie d’app isolée, avec une ancienne version de build, un flux de test et un ZIP signé correspondant au même identifiant. Vérifier le téléchargement, le remplacement et le redémarrage réels. Vérifier le refus d’une archive altérée et l’absence de remplacement en cas d’annulation ou d’échec réseau. Ne pas publier une fausse ancienne version ni une release de test dans le flux stable.
