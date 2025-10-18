#!/bin/sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_ARCHIVE="$SCRIPT_DIR/template.tar.gz.base64"
TEMP_ARCHIVE="$ROOT/.bootstrap-template.tar.gz"

log() {
    printf '%s\n' "$1"
}

init_git() {
    if [ ! -d "$ROOT/.git" ]; then
        log "Initializing git repository"
        git init "$ROOT" >/dev/null
    fi
}

install_tuist() {
    if ! command -v tuist >/dev/null 2>&1; then
        log "Installing Tuist"
        curl -Ls https://install.tuist.io | bash >/dev/null
        export PATH="$HOME/.tuist/bin:$PATH"
    fi
}

materialize_template() {
    if [ ! -f "$TEMPLATE_ARCHIVE" ]; then
        log "Template archive not found: $TEMPLATE_ARCHIVE"
        exit 1
    fi

    log "Materializing project template"
    base64 -d < "$TEMPLATE_ARCHIVE" > "$TEMP_ARCHIVE"
    tar -xzf "$TEMP_ARCHIVE" -C "$ROOT"
    rm -f "$TEMP_ARCHIVE"
}

resolve_packages() {
    install_tuist
    log "Generating workspace via Tuist"
    (cd "$ROOT" && tuist generate --path "$ROOT" >/dev/null)
}

main() {
    init_git
    materialize_template
    resolve_packages
    log "Bootstrap completed"
}

main "$@"
