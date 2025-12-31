#!/usr/bin/env python3
import json
import sys
import re

try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

# Only check Bash commands
if tool_name != "Bash":
    sys.exit(0)

# Extract sleep duration if present
# Matches: sleep 20, sleep 20s, sleep 1m, sleep 5m
sleep_match = re.search(r'sleep\s+(\d+)([smh]?)', command)

if sleep_match:
    duration = int(sleep_match.group(1))
    unit = sleep_match.group(2) or 's'

    # Convert to seconds
    if unit == 'm':
        duration = duration * 60
    elif unit == 'h':
        duration = duration * 3600

    # Reject if > 15 seconds
    if duration > 15:
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"HOOK BLOCKED: Sleep {duration}s exceeds 15s limit! Use shorter sleeps and stay active. Command: {command}"
            }
        }
        print(json.dumps(output))
        sys.exit(0)

# Allow all other commands
sys.exit(0)
