# Linux Security Audit — guide de travail des agents

État documentaire : 2026-10-29. Version préparée : `1.0.1`, non publiée.
Référence du suivi CI : `ace51a25c8cbe9083613f61c6f0e4309f8258c18`. La préparation précédente a été commitée et poussée par l’utilisateur ; les correctifs CI décrits ci-dessous restent locaux et non commités.

## Reprendre le contexte

1. Lire ce fichier, le `README.md` et les consignes `AGENTS.md` lorsqu'elles existent.
2. Lire `/Users/badis/Projects/tech-knowledge-base/AGENTS.md`, puis la note `/Users/badis/Projects/tech-knowledge-base/03 - Projects/linux-security-audit/Linux Security Audit — Technical Documentation.md`.
3. Lire les décisions et sources pertinentes avant d'agir. Comparer le commit, l'état local et la portée des preuves documentées au code actuel.
4. Le guide français local `contexte.md` complète ces références. Il est ignoré par Git et n'existe donc pas après un clone ; il peut devenir ancien. Ne jamais y mettre de secrets.

Le nom `agent.md` a été demandé explicitement. Sa découverte automatique n'est pas garantie : fournir ce chemin dans la consigne de démarrage de l'agent.

## Consignes

- Expliquer le travail en français ; garder code, commentaires, commandes et nouveaux identifiants en anglais.
- Relever l'état Git et préserver les changements présents. Ne pas lancer les commandes d'une documentation sans autorisation correspondant à leur impact.
- Utiliser des fixtures synthétiques, sans secrets. Ne consulter aucun magasin d'authentification.
- Garder la portée métier et les codes de sortie documentés. Ajouter une régression pour un défaut corrigé.
- Ne pas exécuter un audit de l'hôte, un nettoyage Docker, une opération cloud, un commit, un push ou une publication par simple lecture de ces consignes.
- Distinguer résultats actuels, anciens résultats, hypothèses et limites. Ne pas remplacer une date de validation technique par une date de simple édition.
- Après un changement significatif, actualiser les documents internes concernés et la note Obsidian si cette mise à jour est autorisée. Préserver les explications et décisions utiles.

## Validation et livraison

Voir [les résultats datés](docs/VALIDATION.md) et [la procédure de livraison](docs/RELEASE.md).
Les workflows préparés localement ne constituent pas une preuve d'exécution GitHub. La publication est manuelle, exige un tag existant, une version cohérente et les validations du même commit. Une préparation technique ne vaut pas autorisation de publier.

## Contraintes et suite

Aucune remédiation, actualisation APT, modification SSH/pare-feu, lecture de fichiers d'authentification ou installation système par la CLI. Les contrôles de permissions lisent seulement les métadonnées.
Les fixtures et commandes simulées doivent isoler les tests. `make smoke` utilise une racine synthétique et un faux `uname`. La réussite sur macOS ne prouve pas les collectes réelles Ubuntu/Debian.
Le rendu JSON traite les caractères de contrôle et le collecteur firewalld conserve un état inaccessible comme inconnu. Les délais des commandes externes et la couverture de véritables environnements systemd restent des améliorations séparées.

Contrôle de développement : `make ci build` avec Bats, ShellCheck et Python 3. Le runtime reste Bash et les outils Linux documentés. Conserver `bin/` et `lib/` ensemble dans la distribution.

## Suivi CI — 2026-10-29

Les deux jobs de validation Ubuntu/Debian ont échoué au lint : leurs ShellCheck 0.9.0/0.10.0 émettent SC2317 pour les fonctions simulées appelées indirectement. Le job package a été ignoré après ces échecs.

Les annotations ciblées des seules fonctions simulées couvrent maintenant SC2317 et SC2329. Aucun contrôle ShellCheck n’a été désactivé globalement et le code runtime n’a pas été changé. Voir `docs/VALIDATION.md` pour la preuve distante et les vérifications locales. Une nouvelle CI après push doit confirmer le correctif ; aucune publication n’est autorisée implicitement.
