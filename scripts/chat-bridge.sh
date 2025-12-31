#!/bin/bash
# Bridge agent text output to Factorio chat
# Watches .agent-output.jsonl and sends assistant text messages to game

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AGENT_LOG="$PROJECT_DIR/.agent-output.jsonl"

echo "Chat bridge started - watching agent output..."

tail -f "$AGENT_LOG" | while read -r line; do
    # Extract text from assistant messages
    text=$(echo "$line" | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null)
    if [ -n "$text" ] && [ "$text" != "null" ]; then
        # Truncate to 200 chars for chat
        short_text=$(echo "$text" | head -c 200)
        # Send to Factorio via say script
        pnpm --prefix "$PROJECT_DIR" say "$short_text" 2>/dev/null
    fi
done
