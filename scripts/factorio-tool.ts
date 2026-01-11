#!/usr/bin/env tsx
/**
 * Run a Lua tool with parameters
 * Usage: pnpm tool <toolname> [param1=value1] [param2=value2] ...
 *
 * Example: pnpm tool status QUERY=position
 * Example: pnpm tool mine TARGET=iron-ore COUNT=10
 * Example: pnpm tool build ITEM=stone-furnace OFFSET_X=2 OFFSET_Y=0
 */

import * as fs from "fs";
import { spawn } from "child_process";
import * as path from "path";

const toolName = process.argv[2];
const params = process.argv.slice(3);

if (!toolName) {
    console.error("Usage: pnpm tool <toolname> [param1=value1] ...");
    console.error("");
    console.error("Available tools:");
    console.error("  status    - Query game state (QUERY=position|inventory|nearby_resources|buildings|research|all)");
    console.error("  mine      - Mine resources (TARGET=iron-ore COUNT=10)");
    console.error("  walk      - Walk in direction (DIRECTION=north DURATION=2)");
    console.error("  build     - Place building (ITEM=stone-furnace OFFSET_X=2 OFFSET_Y=0)");
    console.error("  craft     - Craft items (RECIPE=iron-gear-wheel CRAFT_COUNT=5)");
    console.error("  interact  - Interact with buildings (ACTION=insert ENTITY_NAME=stone-furnace ITEM_NAME=coal ITEM_COUNT=5)");
    console.error("  research  - Manage research (RESEARCH_ACTION=start TECHNOLOGY=automation)");
    process.exit(1);
}

const toolPath = path.join(process.cwd(), "lua", "api", `${toolName}.lua`);

if (!fs.existsSync(toolPath)) {
    console.error(`Tool not found: ${toolPath}`);
    process.exit(1);
}

// Read the tool file
let luaCode = fs.readFileSync(toolPath, "utf-8");

// Build parameter assignments
const paramAssignments = params.map(p => {
    const eqIndex = p.indexOf("=");
    if (eqIndex === -1) {
        return `${p} = true`;
    }
    const key = p.substring(0, eqIndex);
    let value = p.substring(eqIndex + 1);

    // If value is a number, don't quote it
    if (/^-?\d+(\.\d+)?$/.test(value)) {
        return `${key} = ${value}`;
    }
    // If value is already quoted, use as-is
    if ((value.startsWith("'") && value.endsWith("'")) ||
        (value.startsWith('"') && value.endsWith('"'))) {
        return `${key} = ${value}`;
    }
    // Otherwise, quote it as a string
    return `${key} = "${value}"`;
}).join("; ");

// Find where the IIFE starts and inject parameters before it
// Also wrap the IIFE result in rcon.print so factorio-eval doesn't double-wrap
if (paramAssignments) {
    const iifeStart = luaCode.indexOf("(function()");
    if (iifeStart !== -1) {
        luaCode = luaCode.substring(0, iifeStart) +
                  paramAssignments + ";\n" +
                  luaCode.substring(iifeStart);
    } else {
        luaCode = paramAssignments + ";\n" + luaCode;
    }
}

// Wrap the IIFE result in rcon.print to prevent factorio-eval from adding its own wrapper
// The IIFE pattern ends with "end)()" - we want to capture its return value
luaCode = luaCode.trimEnd();
if (luaCode.endsWith("end)()")) {
    // Transform: ...(function() ... end)()
    // Into: rcon.print(serpent.line((function() ... end)()))
    // Find the start of the IIFE
    const iifeStart = luaCode.lastIndexOf("(function()");
    if (iifeStart !== -1) {
        const before = luaCode.substring(0, iifeStart);
        const iife = luaCode.substring(iifeStart);
        luaCode = before + "rcon.print(serpent.line(" + iife + "))";
    }
}

// Get the directory of this script
const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const evalScript = path.join(scriptDir, "factorio-eval.ts");

// Spawn the eval script with the Lua code as argument
const child = spawn("tsx", [evalScript, luaCode], {
    stdio: "inherit",
    cwd: process.cwd(),
});

child.on("exit", (code) => {
    process.exit(code ?? 0);
});
