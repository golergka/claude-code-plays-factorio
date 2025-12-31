#!/bin/bash
# Take a screenshot every 60 seconds, analyze with OpenAI Vision, send to agent
# Called by PostToolUse hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LAST_SCREENSHOT_FILE="$PROJECT_DIR/.last-screenshot-time"
SCREENSHOT_INTERVAL=60  # seconds

# Get current time
NOW=$(date +%s)

# Get last screenshot time (0 if file doesn't exist)
if [ -f "$LAST_SCREENSHOT_FILE" ]; then
    LAST=$(cat "$LAST_SCREENSHOT_FILE")
else
    LAST=0
fi

# Check if enough time has passed
ELAPSED=$((NOW - LAST))
if [ "$ELAPSED" -ge "$SCREENSHOT_INTERVAL" ]; then
    # Update timestamp first to prevent multiple triggers
    echo "$NOW" > "$LAST_SCREENSHOT_FILE"

    # Run analyze in background and send result as hint
    (
        cd "$PROJECT_DIR"
        ANALYSIS=$(pnpm analyze 2>/dev/null | grep -A 100 "=== SCREENSHOT ANALYSIS ===" | grep -B 100 "=== END ANALYSIS ===" | grep -v "===")
        if [ -n "$ANALYSIS" ]; then
            # Send the analysis as a hint (truncate if too long)
            TRUNCATED=$(echo "$ANALYSIS" | head -30)
            pnpm hint "📸 VISION ANALYSIS: $TRUNCATED" >/dev/null 2>&1
        fi
    ) &
fi

# Always exit 0 - don't block
exit 0
