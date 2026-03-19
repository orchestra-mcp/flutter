#!/usr/bin/env bash
#
# Orchestra Flutter Web — Deployment Script
#
# Builds the Flutter web app, copies the build output to the remote server,
# and restarts Caddy to pick up the new files.
#
# Usage:
#   ./deploy/deploy.sh
#   SERVER_HOST=prod.orchestra-mcp.dev ./deploy/deploy.sh
#   DEPLOY_PATH=/var/www/orchestra ./deploy/deploy.sh
#
# Environment variables:
#   SERVER_HOST  — Remote server hostname or IP (default: orchestra-mcp.dev)
#   DEPLOY_PATH  — Remote path to serve files from (default: /srv/www/orchestra-web)
#   BUILD_DIR    — Local Flutter build output dir (default: build/web)
#   SSH_USER     — SSH user for remote server (default: deploy)
#   SSH_KEY      — Path to SSH private key (default: ~/.ssh/id_ed25519)

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────

SERVER_HOST="${SERVER_HOST:-orchestra-mcp.dev}"
DEPLOY_PATH="${DEPLOY_PATH:-/srv/www/orchestra-web}"
BUILD_DIR="${BUILD_DIR:-build/web}"
SSH_USER="${SSH_USER:-deploy}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"

SSH_OPTS="-o StrictHostKeyChecking=accept-new -i ${SSH_KEY}"
REMOTE="${SSH_USER}@${SERVER_HOST}"

# ── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${BLUE}[deploy]${NC} $1"; }
ok()   { echo -e "${GREEN}[deploy]${NC} $1"; }
warn() { echo -e "${YELLOW}[deploy]${NC} $1"; }
err()  { echo -e "${RED}[deploy]${NC} $1" >&2; }

# ── Pre-flight checks ───────────────────────────────────────────────────────

log "Pre-flight checks..."

if ! command -v flutter &>/dev/null; then
    err "Flutter SDK not found in PATH. Install it first."
    exit 1
fi

if ! command -v rsync &>/dev/null; then
    err "rsync not found. Install it first."
    exit 1
fi

# ── Step 1: Build Flutter web ────────────────────────────────────────────────

log "Building Flutter web (release, CanvasKit renderer)..."
flutter build web --release --web-renderer canvaskit --base-href /

if [ ! -d "${BUILD_DIR}" ]; then
    err "Build directory '${BUILD_DIR}' not found. Build may have failed."
    exit 1
fi

BUILD_SIZE=$(du -sh "${BUILD_DIR}" | cut -f1)
ok "Build complete: ${BUILD_SIZE} in ${BUILD_DIR}"

# ── Step 2: Upload to server ────────────────────────────────────────────────

log "Uploading to ${REMOTE}:${DEPLOY_PATH}..."

# Ensure remote directory exists
ssh ${SSH_OPTS} "${REMOTE}" "mkdir -p ${DEPLOY_PATH}"

# Sync build output to remote server
rsync -avz --delete \
    -e "ssh ${SSH_OPTS}" \
    "${BUILD_DIR}/" \
    "${REMOTE}:${DEPLOY_PATH}/"

ok "Upload complete."

# ── Step 3: Restart Caddy ───────────────────────────────────────────────────

log "Restarting Caddy on ${SERVER_HOST}..."

ssh ${SSH_OPTS} "${REMOTE}" "sudo systemctl reload caddy || sudo caddy reload --config /etc/caddy/Caddyfile"

ok "Caddy reloaded."

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
ok "Deployment complete!"
log "  Server:  ${SERVER_HOST}"
log "  Path:    ${DEPLOY_PATH}"
log "  Size:    ${BUILD_SIZE}"
echo ""
