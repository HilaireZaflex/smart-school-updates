# Mise à jour du module « Vie scolaire » — Guide

## Principe de sécurité des données

- **Les données vivent dans MySQL, le code dans les fichiers.** Une mise à jour ne touche pas aux données.
- Le fichier **`db_import.sql` est strictement additif** : `CREATE TABLE IF NOT EXISTS`, `INSERT ... WHERE NOT EXISTS`. Aucun `DROP`, `DELETE` ni `TRUNCATE` sur les tables de l'école.
- Le package **n'écrase jamais** : `application/config/config.php`, `application/config/database.php`, `application/config/license.php`, `uploads/`, `backup/`.
- Avant chaque mise à jour automatique : **sauvegarde de la base** + **sauvegarde des fichiers remplacés**.

---

## 1. Première installation sur une école (manuelle, ~10 min)

À faire une fois par école (l'updater n'existe pas encore sur l'ancienne version).

1. **Sauvegarder** la base (phpMyAdmin → Exporter) et éventuellement les fichiers.
2. **Uploader** le contenu de `vie_scolaire_v1.0.0.zip` à la **racine du site** via cPanel → Gestionnaire de fichiers, en **écrasant** les fichiers existants.
   - Le zip contient les dossiers `application/` et `database/`, plus `db_import.sql`.
3. **Importer** `db_import.sql` via **phpMyAdmin → Importer** (base de l'école).
   - Additif : les tables existantes et les données ne sont pas modifiées.
4. Se **reconnecter**, puis vérifier :
   - le menu **Vie scolaire** apparaît ;
   - **Paramètres système → Mise à jour du module** affiche **v1.0.0** ;
   - **Vie scolaire → Salles** génère automatiquement les salles depuis les classes/sections.
5. Vider si besoin le cache : supprimer les fichiers de `application/cache/` (sauf `index.html`).

> ⚠️ Le package remplace `sidebar.php`, `dashboard.php`, `routes.php`, `Cron.php` et les fichiers de langue FR/EN. Sur une base 6.3.0 non personnalisée, aucun souci. Si l'école a d'autres personnalisations sur ces fichiers, me le dire : je fournirai un package qui **patche** au lieu d'écraser.

---

## 2. Mises à jour suivantes : GitHub Releases + menu intégré

### Côté éditeur (une fois)

1. Créer un dépôt GitHub **public** (ex. `smart-school-updates`).
2. Construire le package :
   ```bash
   cd database/update_package
   ./build_package.sh 1.0.1 \
     "https://github.com/VOTRE-COMPTE/smart-school-updates/releases/download/v1.0.1" \
     dist
   ```
   → produit `dist/vie_scolaire_v1.0.1.zip` + `dist/manifest.json` (avec SHA-256).
3. Créer une **Release** GitHub avec le tag `v1.0.1` et y **uploader le zip**.
4. Committer/mettre à jour **`manifest.json`** dans le dépôt (branche `main`).
   - URL du manifeste : `https://raw.githubusercontent.com/VOTRE-COMPTE/smart-school-updates/main/manifest.json`

### Côté école (un clic)

1. **Paramètres système → Mise à jour du module**.
2. Coller l'URL du manifeste, **Enregistrer**.
3. **Vérifier les mises à jour** → la nouvelle version et le journal s'affichent.
4. Cocher la confirmation puis **Installer la mise à jour**.
   - Téléchargement + vérification **SHA-256** + sauvegarde base + sauvegarde fichiers + SQL additif + copie des fichiers.
5. La version installée est mise à jour automatiquement.

---

## 3. Sauvegardes & rollback

| Élément | Emplacement |
|---|---|
| Base avant mise à jour | `backup/database_backup/db_pre_update_<date>.sql` |
| Fichiers remplacés | `backup/files_update_<date>/…` |

- **Rollback base** : phpMyAdmin → Importer le dump `db_pre_update_*.sql`.
- **Rollback fichiers** : recopier les fichiers depuis `backup/files_update_<date>/` vers la racine.

---

## 4. Sécurité

- Menu réservé au **Super Admin** (permission `module_update`).
- **SHA-256** vérifié avant application.
- Toujours utiliser une URL **HTTPS** pour le manifeste et le zip.
- Ne jamais mettre l'URL du manifeste en HTTP simple.

---

## 5. Prérequis serveur (cPanel)

- Extensions PHP **curl** et **zip** activées.
- Droits d'écriture sur les fichiers (cas normal en cPanel : PHP tourne avec l'utilisateur du compte).
- **Accès sortant HTTPS** autorisé (pour GitHub).
- Si la sauvegarde complète de la base dépasse la mémoire disponible, l'updater **continue quand même** (le SQL est additif) et l'indique dans le statut ; les fichiers sont, eux, toujours sauvegardés.

---

## 6. Contenu du dépôt local

```
database/
  migrations/
    2026_09_26_vie_scolaire.sql     # tables + permissions + rôle + types
    2026_10_01_module_update.sql    # table app_update + permission
  update_package/
    build_package.sh                # génère zip + manifest.json
    dist/
      vie_scolaire_v1.0.0.zip
      manifest.json
```
