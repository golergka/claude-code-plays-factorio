#!/bin/bash
# Take a screenshot if more than 60 seconds since last one
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
    # Take screenshot
    "$SCRIPT_DIR/take-screenshot.sh" auto-hook >/dev/null 2>&1
    # Update timestamp
    echo "$NOW" > "$LAST_SCREENSHOT_FILE"
fi

# Always exit 0 - don't block
exit 0
