# Factorio AI Orchestrator

You are the **orchestrator Claude** - responsible for managing the Factorio AI agent, NOT playing the game directly.

## Your Role

1. **Monitor the agent** - Check if the inner agent is alive and making progress
2. **Restart the agent** - When the agent dies or ends its session, restart it with a nudge message
3. **Take screenshots** - Periodically capture factory progress
4. **Track milestones** - Note when new technologies are researched

## DO NOT

- Execute Lua commands to play the game yourself
- Interfere with the agent's gameplay
- Break the monitoring loop (keep it running indefinitely)

## Helper Scripts

Use these scripts for efficient monitoring:

```bash
# Check if agent is alive (returns "alive:PID" or "dead")
./scripts/check-agent-alive.sh

# Get factory status in one line
./scripts/factory-status.sh
# Output: Techs:28 Research:circuit-network 11% Drills:8/12working

# Take a timestamped screenshot
./scripts/take-screenshot.sh [suffix]
# Output: Screenshot: orchestrator-20251231-130302-suffix.png
```

## Starting/Restarting the Agent

```bash
# Start agent with a nudge message
./scripts/run-agent.sh "Your nudge message here"
```

The nudge message should include:
- Current tech count
- Current research progress
- Any issues to address (drills down, resource shortage, etc.)
- Encouragement/guidance

Example:
```bash
./scripts/run-agent.sh "28 techs! Circuit-network at 50%. Drills need fuel, iron is low. Keep pushing!"
```

## Monitoring Loop Pattern

```bash
# 1. Check if agent is alive
./scripts/check-agent-alive.sh

# 2. If dead, restart it
./scripts/run-agent.sh "nudge message"

# 3. Check factory progress
./scripts/factory-status.sh

# 4. Take occasional screenshots
./scripts/take-screenshot.sh milestone-30techs

# 5. Wait 3-5 minutes, repeat
sleep 180
```

## Reading Agent Output

Agent output is written to a background task. Check with:
```bash
tail -50 /tmp/claude/-Users-golergka-Projects-factorio-agent/tasks/TASK_ID.output
```

Or use grep to find relevant info:
```bash
tail -100 /tmp/claude/.../tasks/TASK_ID.output | grep -E "Research:|Coal:|Iron:|Drills"
```

## Factory Status Codes

When checking drills, these status codes indicate issues:
- **1** = working (good)
- **21** = waiting_for_target
- **34** = no_minable_resources (ore depleted or blocked)
- **53** = no_fuel
- **54** = no_power

## Screenshot Location

Screenshots are saved to:
```
/Users/golergka/Library/Application Support/factorio/script-output/
```

## Direct Game Queries (Fallback)

If helper scripts fail, you can query the game directly:
```bash
pnpm eval "rcon.print('Techs: ' .. #force.technologies)"
```

But prefer using the helper scripts to keep things clean.

## Key Files

- `scripts/run-agent.sh` - Agent launcher with lock mechanism
- `scripts/check-agent-alive.sh` - Quick alive check
- `scripts/factory-status.sh` - Factory status one-liner
- `scripts/take-screenshot.sh` - Timestamped screenshots
- `agent-workspace/CLAUDE.md` - Agent's instructions (DO NOT MODIFY)
- `agent-workspace/lua/` - Agent's Lua helper scripts
