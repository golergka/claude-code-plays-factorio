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
- Write Lua code for the child agent - let it write its own helpers
- Call scripts directly - ALWAYS use `pnpm run` commands
- Write inline bash commands that need user approval - put them in scripts!

## Scripting Rule

**EVERY TIME you find yourself writing inline bash**, ask: "Should this be a script?"

If the command:
- Needs to be repeatable
- Requires user approval
- Has multiple steps
- Involves sleeping/waiting

Then **PUT IT IN A SCRIPT FILE** and add it to package.json. Never write inline bash that requires approval - it breaks your workflow.

## REMEMBER TO

- **Commit frequently!** After making changes, commit and push them
- Take periodic screenshots to monitor progress
- Check agent status regularly

## Available pnpm Commands

**ALWAYS use these instead of calling scripts directly:**

```bash
# Server management
pnpm server:start          # Start Factorio server (uses latest autosave)

# Agent management
pnpm agent:start            # Start the child agent (kills existing first)
pnpm agent:status           # Check if agent is alive (returns alive:PID or dead)

# Factory monitoring
pnpm factory:status         # One-line factory status
pnpm screenshot [suffix]    # Take timestamped screenshot
pnpm analyze                # OpenAI Vision analysis of current state

# Game interaction (use sparingly - agent should do this)
pnpm eval "lua code"        # Execute Lua code via RCON
pnpm eval:file path.lua     # Execute Lua file via RCON
pnpm say "message"          # Send chat message in game
pnpm hint "message"         # Send hint to child agent (appears in their next output)

# Utilities
pnpm chat:bridge            # Start Twitch chat integration
```

## Starting/Restarting the Agent

```bash
pnpm agent:start "Your nudge message here"
```

The nudge message should include:
- Current tech count
- Current research progress
- Any issues to address (drills down, resource shortage, etc.)

Example:
```bash
pnpm agent:start "28 techs! Gate at 80%. Keep researching!"
```

## Monitoring Loop Pattern

```bash
# 1. Check if agent is alive
pnpm agent:status

# 2. If dead, restart it
pnpm agent:start "nudge message"

# 3. Check factory progress
pnpm factory:status

# 4. Take occasional screenshots
pnpm screenshot milestone-30techs

# 5. Wait, repeat
sleep 180
```

## Reading Agent Output

Agent output is written to a background task. Use TaskOutput tool or:
```bash
tail -50 /tmp/claude/-Users-golergka-Projects-factorio-agent/tasks/TASK_ID.output
```

Filter for key info:
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

## Viewing Screenshots

**IMPORTANT:** You can and should regularly view screenshots to understand factory state!

```bash
pnpm screenshot check
# Then use Read tool to view:
Read "/Users/golergka/Library/Application Support/factorio/script-output/orchestrator-TIMESTAMP-check.png"
```

## Key Files

- `scripts/*.sh` - Helper scripts (use via pnpm, not directly!)
- `scripts/*.ts` - TypeScript tools
- `agent-workspace/CLAUDE.md` - Agent's instructions
- `agent-workspace/lua/` - Agent's Lua helper scripts

## Improving the Child Agent

**IMPORTANT:** You can update the agent's CLAUDE.md with better instructions, but do NOT write Lua code for them. Let the child Claude create its own helpers - this helps it learn and adapt.

What you CAN do:
- Update `agent-workspace/CLAUDE.md` with better instructions/patterns
- Add clarifications when agent struggles

What you should NOT do:
- Write Lua helper files for the agent
- Directly modify agent's lua/ directory

After updating CLAUDE.md, restart the agent:
```bash
pnpm agent:start "CLAUDE.md updated! Check the new instructions."
```
