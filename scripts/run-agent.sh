#!/bin/bash
#
# Factorio AI Agent Runner
#
# This script runs Claude Code in headless mode, continuously restarting
# when the conversation ends. This creates a persistent AI agent that
# can play Factorio indefinitely.
#
# Usage: ./scripts/run-agent.sh
#
# Press Ctrl+C to stop the agent.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Session name for conversation persistence
SESSION_NAME="factorio-agent"

echo "========================================"
echo "  Factorio AI Agent"
echo "========================================"
echo ""
echo "Starting Claude Code in continuous mode..."
echo "The agent will play Factorio via RCON."
echo "Press Ctrl+C to stop."
echo ""
echo "----------------------------------------"

# Trap Ctrl+C for graceful shutdown
cleanup() {
    echo ""
    echo "Shutting down Factorio AI Agent..."
    exit 0
}
trap cleanup SIGINT SIGTERM

# Main loop - keep restarting Claude Code
while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting agent session..."

    # Run Claude Code in headless mode with conversation resume
    # --continue: Resume the previous conversation if it exists
    # --dangerously-skip-permissions: Skip permission prompts (use with caution)
    if claude --continue --dangerously-skip-permissions \
        --print "You are a Factorio AI agent. Check your current game state and continue building your factory. Start by running: pnpm eval \"game.player.position\" to see where you are."; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended normally"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended with error (exit code: $?)"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarting in 3 seconds..."
    sleep 3
done
