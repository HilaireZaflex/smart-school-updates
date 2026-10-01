#!/usr/bin/env bash
# ============================================================================
#  Publication d'une mise à jour Smart School sur GitHub (sans gh)
# ----------------------------------------------------------------------------
#  Le jeton GitHub est lu automatiquement dans le trousseau macOS
#  (entrée « github.com »), ou dans la variable GITHUB_TOKEN.
#
#  Usage :
#     ./publish.sh 1.0.0
#     REPO=compte/depot ./publish.sh 1.0.1
#
#  Le zip doit être présent à côté de ce script :
#     vie_scolaire_v<version>.zip
# ============================================================================
set -euo pipefail

OWNER_REPO="${REPO:-HilaireZaflex/smart-school-updates}"
VERSION="${1:?Usage: ./publish.sh <version>}"
ZIP="vie_scolaire_v${VERSION}.zip"

API="https://api.github.com"
UP="https://uploads.github.com"
TOKEN="${GITHUB_TOKEN:-$(security find-internet-password -w -s github.com 2>/dev/null || true)}"

cd "$(dirname "$0")"

[ -n "$TOKEN" ] || { echo "Aucun jeton GitHub (trousseau ou GITHUB_TOKEN)."; exit 1; }
[ -f "$ZIP" ]   || { echo "Fichier manquant : $ZIP"; exit 1; }
command -v jq >/dev/null || { echo "jq requis (brew install jq)."; exit 1; }

AUTH=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json")

DL_URL="https://github.com/${OWNER_REPO}/releases/download/v${VERSION}/${ZIP}"
SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"

cat > manifest.json <<JSON
{
  "module": "vie_scolaire",
  "latest_version": "${VERSION}",
  "min_app_version": "6.3.0",
  "download_url": "${DL_URL}",
  "sha256": "${SHA256}",
  "changelog": "Module Vie scolaire : visites de salle, reclamations/suggestions, evaluations des enseignants, QR par salle, notifications et rapport hebdomadaire WhatsApp.",
  "released_at": "$(date +%Y-%m-%d)"
}
JSON

# --- 1. Dépôt (créé s'il n'existe pas) ---
if ! curl -s -f -o /dev/null -H "Authorization: Bearer $TOKEN" "$API/repos/${OWNER_REPO}"; then
  OWNER="${OWNER_REPO%%/*}"
  NAME="${OWNER_REPO##*/}"
  curl -s -X POST "${AUTH[@]}" "$API/user/repos" \
    -d "$(jq -n --arg n "$NAME" '{name:$n,description:"Mises a jour Smart School - module Vie scolaire",public:true,has_issues:false,has_wiki:false}')" \
    | jq -r '.full_name // .message'
fi

# --- 2. Fichiers manifeste + README (création ou mise à jour) ---
put_file() {
  local path="$1" msg="$2" sha content payload
  sha="$(curl -s "${AUTH[@]}" "$API/repos/${OWNER_REPO}/contents/${path}" | jq -r '.sha // empty')"
  content="$(base64 < "$path" | tr -d '\n')"
  if [ -n "$sha" ]; then
    payload="$(jq -n --arg m "$msg" --arg c "$content" --arg s "$sha" '{message:$m,content:$c,sha:$s,branch:"main"}')"
  else
    payload="$(jq -n --arg m "$msg" --arg c "$content" '{message:$m,content:$c,branch:"main"}')"
  fi
  curl -s -X PUT "${AUTH[@]}" "$API/repos/${OWNER_REPO}/contents/${path}" -d "$payload" | jq -r '.content.path // .message'
}
if [ -f README.md ]; then put_file README.md "readme"; fi
put_file manifest.json "manifest v${VERSION}"

# --- 3. Release (créée si absente) ---
REL_ID="$(curl -s "${AUTH[@]}" "$API/repos/${OWNER_REPO}/releases/tags/v${VERSION}" | jq -r '.id // empty')"
if [ -z "$REL_ID" ] || [ "$REL_ID" = "null" ]; then
  REL_ID="$(curl -s -X POST "${AUTH[@]}" "$API/repos/${OWNER_REPO}/releases" \
    -d "$(jq -n --arg t "v${VERSION}" --arg n "Vie scolaire v${VERSION}" '{tag_name:$t,name:$n,body:"Module Vie scolaire : visites, reclamations, evaluations, QR, notifications, rapport WhatsApp.",draft:false,prerelease:false}')" \
    | jq -r '.id')"
fi
echo "Release v${VERSION} (id ${REL_ID})"

# --- 4. Asset (remplacé si déjà présent) ---
ASSET_ID="$(curl -s "${AUTH[@]}" "$API/repos/${OWNER_REPO}/releases/${REL_ID}/assets" | jq -r --arg n "$ZIP" '.[] | select(.name==$n) | .id')"
if [ -n "$ASSET_ID" ] && [ "$ASSET_ID" != "null" ]; then
  curl -s -X DELETE "${AUTH[@]}" "$API/repos/${OWNER_REPO}/releases/assets/${ASSET_ID}"
fi
curl -s -X POST "${AUTH[@]}" -H "Content-Type: application/zip" --data-binary @"$ZIP" \
  "${UP}/repos/${OWNER_REPO}/releases/${REL_ID}/assets?name=${ZIP}" | jq -r '.name // .message'

echo
echo "======================================================================"
echo " URL du manifeste à saisir dans l'application :"
echo "   https://raw.githubusercontent.com/${OWNER_REPO}/main/manifest.json"
echo "======================================================================"
