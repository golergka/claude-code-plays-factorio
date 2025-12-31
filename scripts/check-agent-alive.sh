#!/bin/bash
# Quick check if agent is alive. Returns:
# - "alive:PID" if agent is running
# - "dead" if agent is not running
# Exit code: 0 if alive, 1 if dead

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOCK_PID_FILE="$PROJECT_DIR/.agent.lock.d/pid"

# Check if lock file exists and contains a valid PID
if [ -f "$LOCK_PID_FILE" ]; then
    PID=$(cat "$LOCK_PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "alive:$PID"
        exit 0
    fi
fi

echo "dead"
exit 1
