#!/bin/bash
# Factorio Multi-Agent System Entry Point
# Starts the Orchestrator agent which manages all other agents

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "=== Factorio Multi-Agent System ==="
echo "Project directory: $PROJECT_DIR"

# Check if claude-runner is available
if ! command -v claude-runner &> /dev/null; then
    echo "ERROR: claude-runner not found. Please install it first."
    exit 1
fi

# Check if mcp_agent_mail server is running
if ! curl -s http://localhost:8765/mcp/ > /dev/null 2>&1; then
    echo "WARNING: mcp_agent_mail server not responding on port 8765"
    echo "Starting mcp_agent_mail server..."
    cd /Users/golergka/Projects/mcp_agent_mail
    source .venv/bin/activate
    python -m mcp_agent_mail.cli serve-http --port 8765 &
    sleep 3
    cd "$PROJECT_DIR"
fi

# Check if Factorio server is running (test RCON connection)
if ! pnpm eval "game.tick" > /dev/null 2>&1; then
    echo "Starting Factorio server..."
    pnpm server:start &
    sleep 5
    echo "Waiting for server to be ready..."
    for i in {1..30}; do
        if pnpm eval "game.tick" > /dev/null 2>&1; then
            echo "Factorio server is ready!"
            break
        fi
        sleep 1
    done
fi

# Create logs directory if not exists
mkdir -p logs

# Clear old output logs
rm -f logs/output-*.jsonl

echo ""
echo "Starting Orchestrator agent..."
echo "The Orchestrator will spawn Tool Creator, Player, and Strategist agents."
echo ""

# Start the Orchestrator
# It will read its instructions from CLAUDE.md and spawn child agents
claude-runner \
    --task-file "$PROJECT_DIR/CLAUDE.md" \
    --working-dir "$PROJECT_DIR" \
    --session-id factorio-orchestrator
