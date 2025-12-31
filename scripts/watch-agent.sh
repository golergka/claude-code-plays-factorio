#!/bin/bash
#
# Factorio AI Agent Watcher
#
# This script watches the agent output log and displays it with colors.
# Run this in a separate terminal to monitor the agent.
#
# Usage: ./scripts/watch-agent.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

AGENT_LOG="$PROJECT_DIR/.agent-output.jsonl"

echo "========================================"
echo "  Factorio AI Agent Watcher"
echo "========================================"
echo ""
echo "Watching agent output..."
echo "Press Ctrl+C to stop."
echo ""
echo "----------------------------------------"

# Create log file if it doesn't exist
touch "$AGENT_LOG"

# Tail the log and pretty-print with colors
tail -f "$AGENT_LOG" | jq --unbuffered -C .
