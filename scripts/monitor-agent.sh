#!/bin/bash
# Monitor agent output with truncation (for parent Claude)
# Shows only the last N lines of the agent log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AGENT_LOG="$PROJECT_DIR/.agent-output.jsonl"

# Show only last 30 lines, extract key info
tail -30 "$AGENT_LOG" 2>/dev/null | jq -c 'select(.type == "assistant" or .type == "user") | {type, text: .message.content[0].text?, tool: .message.content[0].name?, result: .tool_use_result.stdout? | if . then (. | split("\n") | last) else null end}' 2>/dev/null | tail -10
