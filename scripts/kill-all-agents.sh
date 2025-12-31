#!/bin/bash
# Kill ALL child Claude agents (not the orchestrator)
# The orchestrator runs in a terminal (S+), child agents run detached (??)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Find all Claude processes in agent-workspace directory
AGENT_PIDS=$(lsof 2>/dev/null | grep "claude" | grep "agent-workspace" | awk '{print $2}' | sort -u)

if [ -z "$AGENT_PIDS" ]; then
    echo "No child agents found"
else
    for PID in $AGENT_PIDS; do
        echo "Killing child agent PID $PID"
        kill -9 "$PID" 2>/dev/null
    done
fi

# Also kill any lingering sleep processes from agents
pkill -9 -f "sleep.*factorio-agent" 2>/dev/null

# Clean up lock files
rm -rf "$PROJECT_DIR/.agent.lock.d" "$PROJECT_DIR/.agent.lock" "$PROJECT_DIR/.agent.pid" 2>/dev/null

echo "All child agents killed"
