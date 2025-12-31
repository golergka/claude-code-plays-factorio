#!/bin/bash
# Take a timestamped screenshot
# Usage: ./scripts/take-screenshot.sh [optional-suffix]

SUFFIX="${1:-snapshot}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILENAME="orchestrator-${TIMESTAMP}-${SUFFIX}.png"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"
pnpm eval "game.take_screenshot{player=player, position=player.position, resolution={1920,1080}, zoom=0.5, path='$FILENAME', show_entity_info=true}; rcon.print('Screenshot: $FILENAME')" 2>/dev/null | tail -1
