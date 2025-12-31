#!/bin/bash
# Factorio AI Agent Runner
# Simple and reliable - kills any existing agents before starting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# ALWAYS kill existing agents first - no exceptions
echo "Killing any existing agents..."
"$SCRIPT_DIR/kill-all-agents.sh"

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

# Run agent
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
