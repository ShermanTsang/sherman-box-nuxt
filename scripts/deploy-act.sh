#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: scripts/deploy-act.sh [act options]"
  echo "Configure .env for site settings and .act.secrets for TCR credentials."
  echo "Copy .act.secrets.example to .act.secrets, then fill in the credentials."
  echo "Example: scripts/deploy-act.sh --dryrun"
  exit 0
fi

if ! command -v act >/dev/null 2>&1; then
  echo "act is required: https://nektosact.com/installation/" >&2
  exit 1
fi
if [ ! -f .env ]; then
  echo "Missing .env; copy .env-example and fill in the site configuration." >&2
  exit 1
fi
if [ ! -f .act.secrets ]; then
  echo "Missing .act.secrets; copy .act.secrets.example and fill in the TCR credentials." >&2
  exit 1
fi

# Only pass the workflow's expected keys through act's secrets interface.
# Keep registry credentials out of the app's .env and out of container envs.
secret_file="$(mktemp "${TMPDIR:-/tmp}/sherman-box-act-secrets.XXXXXXXX")"
trap 'rm -f "$secret_file"' EXIT
awk '/^[[:space:]]*(SITE_NAME|SITE_DESCRIPTION|SITE_KEYWORDS|SITE_DOMAIN)[[:space:]]*=/ { print }' .env >"$secret_file"
awk '/^[[:space:]]*(TCR_REGISTRY|TCR_NAMESPACE|TCR_USERNAME|TCR_PASSWORD)[[:space:]]*=/ { print }' .act.secrets >>"$secret_file"

act workflow_dispatch \
  -W .github/workflows/build_tencent_tcr.yml \
  --env-file /dev/null \
  --secret-file "$secret_file" \
  "$@"
