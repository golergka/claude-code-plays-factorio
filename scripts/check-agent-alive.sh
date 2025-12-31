#!/bin/bash
# Check if a child agent is running
# Returns: "alive:PID" or "dead"
# Exit: 0 if alive, 1 if dead

# Find Claude processes in agent-workspace
AGENT_PID=$(lsof 2>/dev/null | grep "claude" | grep "agent-workspace" | awk '{print $2}' | sort -u | head -1)

if [ -n "$AGENT_PID" ]; then
    echo "alive:$AGENT_PID"
    exit 0
else
    echo "dead"
    exit 1
fi
