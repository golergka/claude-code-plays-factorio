#!/bin/bash
# Factorio AI Agent Runner
# Ensures only ONE agent runs at a time by killing any existing ones first

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Kill any existing Claude agents in agent-workspace before starting
echo "Checking for existing agents..."
EXISTING_PIDS=$(lsof 2>/dev/null | grep "claude" | grep "agent-workspace" | awk '{print $2}' | sort -u)
if [ -n "$EXISTING_PIDS" ]; then
    for PID in $EXISTING_PIDS; do
        echo "Killing existing agent PID $PID"
        kill -9 "$PID" 2>/dev/null || true
    done
    sleep 1
fi

# Also kill lingering sleep processes from old agents
pkill -9 -f "sleep.*factorio-agent" 2>/dev/null || true

AGENT_LOG="$PROJECT_DIR/.agent-output.jsonl"
CLAUDE_BIN="$HOME/.claude/local/claude"

echo "========================================"
echo "  Factorio AI Agent"
echo "========================================"

NUDGE="${1:-}"
if [ -n "$NUDGE" ]; then
    echo "Nudge: $NUDGE"
fi

echo "Starting Claude Code..."

cd "$PROJECT_DIR/agent-workspace"
PROMPT="You are a Factorio AI agent playing Factorio. Run commands from $PROJECT_DIR directory."

if echo "$PROMPT" | stdbuf -oL "$CLAUDE_BIN" --continue --dangerously-skip-permissions \
    --verbose \
    --print \
    --output-format stream-json \
    --add-dir "$PROJECT_DIR" \
    ${NUDGE:+--append-system-prompt "URGENT HINT: $NUDGE"} \
    | tee -a "$AGENT_LOG" \
    | jq --unbuffered -C .; then
    echo "Agent ended normally"
else
    echo "Agent ended with error (exit code: $?)"
fi
