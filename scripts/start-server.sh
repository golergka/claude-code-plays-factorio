#!/bin/bash
#
# Start Factorio Server with RCON
#
# This script starts a Factorio headless server with RCON enabled.
# Uses a separate data directory to allow running alongside the game client.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
fi

# Factorio paths
FACTORIO_APP="/Users/golergka/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app"
FACTORIO_BIN="$FACTORIO_APP/Contents/MacOS/factorio"

# Server uses separate data directory to avoid conflicts with game client
SERVER_DATA="$HOME/Library/Application Support/factorio-server"
SERVER_CONFIG="$SERVER_DATA/config/config.ini"
SAVE_FILE="$SERVER_DATA/saves/claude-agent.zip"

# RCON settings
RCON_PORT="${FACTORIO_RCON_PORT:-27015}"
RCON_PASSWORD="${FACTORIO_RCON_PASSWORD:-claudeagent2024}"

# Find the best save to load (prefer autosaves over main save)
# Autosaves are in the saves directory as _autosave*.zip
find_best_save() {
    local saves_dir="$SERVER_DATA/saves"

    # Look for most recent autosave
    local latest_autosave=$(ls -t "$saves_dir"/_autosave*.zip 2>/dev/null | head -1)
    if [ -n "$latest_autosave" ] && [ -f "$latest_autosave" ]; then
        echo "$latest_autosave"
        return
    fi

    # Fall back to main save
    if [ -f "$SAVE_FILE" ]; then
        echo "$SAVE_FILE"
        return
    fi

    # No save exists - will create new
    echo ""
}

LOAD_SAVE=$(find_best_save)
if [ -z "$LOAD_SAVE" ]; then
    echo "No existing save found - will create new game"
    LOAD_SAVE="$SAVE_FILE"
fi

echo "========================================"
echo "  Factorio AI Server"
echo "========================================"
echo ""
echo "Starting Factorio server..."
echo "  Loading: $LOAD_SAVE"
echo "  RCON Port: $RCON_PORT"
echo "  Game Port: 34197"
echo ""
echo "Connect to the game via:"
echo "  Multiplayer -> Connect to address -> localhost"
echo ""
echo "Press Ctrl+C to stop the server."
echo "----------------------------------------"

exec "$FACTORIO_BIN" \
    --config "$SERVER_CONFIG" \
    --start-server "$LOAD_SAVE" \
    --rcon-port "$RCON_PORT" \
    --rcon-password "$RCON_PASSWORD"
