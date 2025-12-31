#!/bin/bash
#
# Start Factorio Server with RCON
#
# This script starts a Factorio headless server with RCON enabled.
# The server runs the AI agent save file.
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
SAVE_FILE="$HOME/Library/Application Support/factorio/saves/claude-agent.zip"

# RCON settings
RCON_PORT="${FACTORIO_RCON_PORT:-27015}"
RCON_PASSWORD="${FACTORIO_RCON_PASSWORD:-claudeagent2024}"

echo "========================================"
echo "  Factorio AI Server"
echo "========================================"
echo ""
echo "Starting Factorio server..."
echo "  Save: $SAVE_FILE"
echo "  RCON Port: $RCON_PORT"
echo "  Game Port: 34197"
echo ""
echo "Connect to the game via:"
echo "  Multiplayer -> Connect to address -> localhost"
echo ""
echo "Press Ctrl+C to stop the server."
echo "----------------------------------------"

exec "$FACTORIO_BIN" \
    --start-server "$SAVE_FILE" \
    --rcon-port "$RCON_PORT" \
    --rcon-password "$RCON_PASSWORD"
