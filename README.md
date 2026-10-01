# Mises à jour Smart School — module « Vie scolaire »

Ce dépôt public héberge le manifeste et les packages de mise à jour du module **Vie scolaire**.

- `manifest.json` : version disponible, URL du zip, SHA-256, journal.
- Les packages sont attachés aux **Releases** (ex. `v1.0.0`).

## Installation / mise à jour

Dans le logiciel : **Paramètres système → Mise à jour du module**, coller l'adresse du manifeste :

```
https://raw.githubusercontent.com/HilaireZaflex/smart-school-updates/main/manifest.json
```

Puis **Vérifier les mises à jour** → **Installer**.

## Nouvelle version

```bash
cd /Users/nms/coolmo/database/update_package
./build_package.sh 1.0.1 \
  "https://github.com/HilaireZaflex/smart-school-updates/releases/download/v1.0.1" \
  dist
```

Puis créer une Release `v1.0.1`, y attacher le zip, et mettre à jour `manifest.json`.
