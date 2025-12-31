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

# Lock directory for atomic locking (mkdir is atomic on POSIX)
LOCK_DIR="$PROJECT_DIR/.agent.lock.d"
LOCK_PID_FILE="$LOCK_DIR/pid"

# Attempt to acquire lock atomically
acquire_lock() {
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        # Got the lock - write our PID
        echo $$ > "$LOCK_PID_FILE"
        return 0
    else
        # Lock exists - check if holder is alive
        if [ -f "$LOCK_PID_FILE" ]; then
            EXISTING_PID=$(cat "$LOCK_PID_FILE" 2>/dev/null)
            if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" 2>/dev/null; then
                echo "ERROR: Agent already running (PID $EXISTING_PID)"
                echo "Kill it first: kill $EXISTING_PID"
                return 1
            else
                # Stale lock - remove and retry
                echo "Removing stale lock (process $EXISTING_PID not running)..."
                rm -rf "$LOCK_DIR"
                if mkdir "$LOCK_DIR" 2>/dev/null; then
                    echo $$ > "$LOCK_PID_FILE"
                    return 0
                fi
            fi
        fi
        echo "ERROR: Could not acquire lock"
        return 1
    fi
}

# Try to acquire lock
if ! acquire_lock; then
    exit 1
fi

echo "Lock acquired (PID $$)"

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
    rm -rf "$LOCK_DIR"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# Run agent once (parent Claude manages restarts)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting agent session..."

# Run Claude Code in headless mode with conversation resume
# --continue: Resume the previous conversation if it exists
# --dangerously-skip-permissions: Skip permission prompts for automation
# --output-format stream-json: Real-time streaming JSON output
# Run from .agent-workspace subdirectory for separate session context
# Use --add-dir to give access to parent project
PROMPT="You are a Factorio AI agent playing Factorio. Run commands from $PROJECT_DIR directory. Check game state: pnpm --prefix $PROJECT_DIR eval player.position"
cd "$PROJECT_DIR/agent-workspace"
if echo "$PROMPT" | stdbuf -oL "$CLAUDE_BIN" --continue --dangerously-skip-permissions \
    --verbose \
    --print \
    --output-format stream-json \
    --add-dir "$PROJECT_DIR" \
    ${NUDGE:+--append-system-prompt "URGENT HINT: $NUDGE"} \
    | tee -a "$AGENT_LOG" \
    | jq --unbuffered -C .; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended normally"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent session ended with error (exit code: $?)"
fi
