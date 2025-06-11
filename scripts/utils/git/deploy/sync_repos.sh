#!/usr/bin/env bash
source "$(dirname "$0")/deploykey.conf"

eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add "$KEY_PATH" >/dev/null 2>&1

TITLE="Deploy key $(date +'%Y-%m-%d')"

for entry in "${REPO_CONFIG[@]}"; do
  IFS='|' read -r field path branch <<< "$entry"

  # Determinar URL y owner/repo
  if [[ "$field" == *@* ]]; then
    url="$field"
    owner_repo="${field#*:}"
    owner_repo="${owner_repo%.git}"
  else
    owner_repo="$field"
    url="git@github.com:${owner_repo}.git"
  fi

  # Asegurarnos de que existe el repo local
  if [[ ! -d "$path/.git" ]]; then
    echo "✖ No es repositorio Git: $path"
    continue
  fi

  echo "→ Procesando $owner_repo en $path (rama: $branch)"

  git -C "$path" remote set-url origin "$url"
  if ! git -C "$path" fetch origin; then
    echo "✖ falló git fetch en $owner_repo"
    continue
  fi

  git -C "$path" branch -M "$branch"
  if ! git -C "$path" push -u origin "$branch"; then
    echo "✖ falló git push en $owner_repo"
  fi

  KEY=$(<"$KEY_PATH")
  http_code=$(curl -s -o /tmp/resp.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$TITLE\",\"key\":\"$KEY\",\"read_only\":false}" \
    "https://api.github.com/repos/$owner_repo/keys")

  if [[ "$http_code" -eq 201 ]]; then
    echo "✔ Deploy key añadida a $owner_repo"
  elif [[ "$http_code" -eq 422 ]]; then
    echo "■ La deploy key ya existe en $owner_repo"
  else
    msg=$(jq -r '.message' /tmp/resp.json 2>/dev/null)
    echo "✖ API error ($http_code) en $owner_repo: $msg"
  fi
done
