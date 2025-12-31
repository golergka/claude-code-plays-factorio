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

# Log file for agent output (can be watched by watch-agent.sh)
AGENT_LOG="$PROJECT_DIR/.agent-output.jsonl"

# Claude Code path (it's installed as an alias, so we use the direct path)
CLAUDE_BIN="$HOME/.claude/local/claude"

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

# Optional temporary nudge from command line
NUDGE="${1:-}"
if [ -n "$NUDGE" ]; then
    echo "Temporary nudge: $NUDGE"
fi

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
    # --dangerously-skip-permissions: Skip permission prompts for automation
    # --output-format stream-json: Real-time streaming JSON output
    # Pipe through claude-code-log for readable output
    # Run from .agent-workspace subdirectory for separate session context
    # Use --add-dir to give access to parent project
    cd "$PROJECT_DIR/agent-workspace"
    if stdbuf -oL "$CLAUDE_BIN" --continue --dangerously-skip-permissions \
        --verbose \
        --print \
        --output-format stream-json \
        --add-dir "$PROJECT_DIR" \
        ${NUDGE:+--append-system-prompt "URGENT HINT: $NUDGE"} \
        "You are a Factorio AI agent playing Factorio. Run commands from $PROJECT_DIR directory. Check game state: pnpm --prefix $PROJECT_DIR eval \"player.position\"" \
        | tee -a "$AGENT_LOG" \
        | jq --unbuffered -C .; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended normally"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended with error (exit code: $?)"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restarting in 3 seconds..."
    sleep 3
done
