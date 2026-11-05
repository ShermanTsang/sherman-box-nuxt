#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: scripts/deploy-act.sh [act options]"
  echo "Configure .env, then run this script to build and push to TCR."
  echo "Example: scripts/deploy-act.sh --dryrun"
  exit 0
fi

if ! command -v act >/dev/null 2>&1; then
  echo "act is required: https://nektosact.com/installation/" >&2
  exit 1
fi
if [ ! -f .env ]; then
  echo "Missing .env; copy .env-example and fill in the configuration." >&2
  exit 1
fi

# act otherwise loads .env into every container, including TCR credentials.
# Pass only the workflow's expected keys through its secrets interface.
secret_file="$(mktemp "${TMPDIR:-/tmp}/sherman-box-act-secrets.XXXXXXXX")"
trap 'rm -f "$secret_file"' EXIT
awk '/^[[:space:]]*(TCR_REGISTRY|TCR_NAMESPACE|TCR_USERNAME|TCR_PASSWORD|SITE_NAME|SITE_DESCRIPTION|SITE_KEYWORDS|SITE_DOMAIN)[[:space:]]*=/ { print }' .env >"$secret_file"

act workflow_dispatch \
  -W .github/workflows/build_tencent_tcr.yml \
  --env-file /dev/null \
  --secret-file "$secret_file" \
  "$@"
