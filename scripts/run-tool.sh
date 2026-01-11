#!/bin/bash
# Run a Lua tool with parameters
# Usage: ./scripts/run-tool.sh <tool> <params>
# Example: ./scripts/run-tool.sh mine "TARGET='iron-ore'; COUNT=10"
# Example: ./scripts/run-tool.sh status "QUERY='position'"

TOOL=$1
PARAMS=$2

if [ -z "$TOOL" ]; then
    echo "Usage: ./scripts/run-tool.sh <tool> [params]"
    echo "Available tools: status, mine, walk, build, craft, interact, research"
    exit 1
fi

TOOL_PATH="lua/api/${TOOL}.lua"
if [ ! -f "$TOOL_PATH" ]; then
    echo "Tool not found: $TOOL_PATH"
    exit 1
fi

# Read the tool file and prepend parameters
TOOL_CODE=$(cat "$TOOL_PATH")

if [ -n "$PARAMS" ]; then
    FULL_CODE="${PARAMS}; ${TOOL_CODE}"
else
    FULL_CODE="$TOOL_CODE"
fi

# Execute via pnpm eval
pnpm eval "$FULL_CODE"
