#!/bin/sh
# ===========================================================================
# n8n entrypoint wrapper for TerraMaster TOS 7
# ===========================================================================
# The upstream image runs fine as the unprivileged "node" user (uid 1000), so
# nothing has to be relocated here. This wrapper only solves the one thing the
# official image cannot know by itself: the address you use to reach this NAS.
#
# n8n builds every webhook, form, OAuth-callback and editor link from
# WEBHOOK_URL / N8N_EDITOR_BASE_URL, and falls back to http://localhost:5678/,
# which no other device can reach. If an optional file called public-url.txt
# exists in the application data folder, its first non-comment line is used as
# the public base URL. The file lives in the data volume (not in the
# platform-managed package directory), so the setting survives container
# updates and reinstalls.
#
# MAINTAINERS: this file is embedded into docker-compose.yml by
# scripts/build.sh, which indents it and escapes every dollar sign as two
# dollar signs (docker compose would otherwise interpolate them). Edit THIS
# file only, and never write a doubled dollar sign here.
# ===========================================================================
set -u

DATA_DIR=/home/node/.n8n
PUBLIC_URL_FILE="$DATA_DIR/public-url.txt"

mkdir -p "$DATA_DIR" 2>/dev/null || true

# Seed a commented sample once, so the option is discoverable in the NAS file
# manager. It is written only when missing; an existing file is never touched.
if [ ! -e "$PUBLIC_URL_FILE" ]; then
  printf '%s\n' \
    '# Optional: the address you use to reach this n8n from other devices.' \
    '# n8n builds webhook, form and OAuth links from it; without a value they' \
    '# point at http://localhost:5678/ and only work on the NAS itself.' \
    '# Uncomment the next line, adapt IP and port, then restart the app:' \
    '#http://192.168.1.10:8001/' \
    > "$PUBLIC_URL_FILE" 2>/dev/null || true
fi

url=$(sed -e 's/#.*$//' "$PUBLIC_URL_FILE" 2>/dev/null \
      | grep -v '^[[:space:]]*$' \
      | head -n 1 \
      | tr -d '[:space:]')

if [ -n "$url" ]; then
  case "$url" in
    http://*|https://*)
      export WEBHOOK_URL="$url"
      export N8N_EDITOR_BASE_URL="$url"
      printf '[n8n] public URL: %s\n' "$url"
      ;;
    *)
      printf '[n8n] public-url.txt: "%s" is not an http(s) URL - ignored\n' "$url"
      ;;
  esac
else
  printf '[n8n] no public URL set; webhook/form links use http://localhost:5678/\n'
fi

exec tini -- /docker-entrypoint.sh "$@"
