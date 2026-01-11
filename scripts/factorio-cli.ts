#!/usr/bin/env tsx
/**
 * Factorio CLI - Player's interface to the game
 *
 * Usage: factorio <command> [args...]
 *
 * Examples:
 *   factorio status
 *   factorio walk north 2
 *   factorio mine iron-ore 10
 *   factorio build stone-furnace 2 0
 *   factorio craft iron-gear-wheel 5
 *   factorio interact insert stone-furnace coal 10
 *   factorio research start automation
 *   factorio screenshot
 *   factorio say "Hello world"
 */

import * as fs from "fs";
import * as path from "path";
import { spawn, spawnSync } from "child_process";

// Project root (one level up from scripts/)
const projectRoot = path.dirname(path.dirname(new URL(import.meta.url).pathname));
const luaApiDir = path.join(projectRoot, "lua", "api");
const logsDir = path.join(projectRoot, "logs");

// Ensure logs directory exists
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Tool definitions: maps command args to Lua globals
interface ToolDef {
    description: string;
    params: { name: string; luaGlobal: string; description: string; required?: boolean }[];
    examples: string[];
}

const TOOLS: Record<string, ToolDef> = {
    status: {
        description: "Query game state",
        params: [
            { name: "query", luaGlobal: "QUERY", description: "What to query: position, inventory, nearby_resources, buildings, research, walking, all", required: false },
            { name: "radius", luaGlobal: "RADIUS", description: "Search radius (default: 50)", required: false }
        ],
        examples: [
            "factorio status",
            "factorio status position",
            "factorio status inventory",
            "factorio status nearby_resources 100"
        ]
    },
    walk: {
        description: "Walk in a direction for a duration",
        params: [
            { name: "direction", luaGlobal: "DIRECTION", description: "north, south, east, west, ne, nw, se, sw", required: true },
            { name: "duration", luaGlobal: "DURATION", description: "Seconds to walk (default: 1, max: 5)", required: false }
        ],
        examples: [
            "factorio walk north",
            "factorio walk east 3",
            "factorio walk sw 2"
        ]
    },
    mine: {
        description: "Mine nearby resources",
        params: [
            { name: "target", luaGlobal: "TARGET", description: "Resource type: iron-ore, copper-ore, coal, stone, etc.", required: true },
            { name: "count", luaGlobal: "COUNT", description: "How many to mine (default: 1)", required: false }
        ],
        examples: [
            "factorio mine iron-ore",
            "factorio mine coal 20",
            "factorio mine stone 50"
        ]
    },
    build: {
        description: "Place a building near player",
        params: [
            { name: "item", luaGlobal: "ITEM", description: "Item to place: stone-furnace, burner-mining-drill, etc.", required: true },
            { name: "offset_x", luaGlobal: "OFFSET_X", description: "X offset from player (default: 1)", required: false },
            { name: "offset_y", luaGlobal: "OFFSET_Y", description: "Y offset from player (default: 0)", required: false },
            { name: "direction", luaGlobal: "BUILD_DIRECTION", description: "Facing: north, south, east, west (default: north)", required: false }
        ],
        examples: [
            "factorio build stone-furnace",
            "factorio build burner-mining-drill 2 0",
            "factorio build inserter 3 1 east"
        ]
    },
    craft: {
        description: "Craft items",
        params: [
            { name: "recipe", luaGlobal: "RECIPE", description: "Recipe name: iron-gear-wheel, electronic-circuit, etc.", required: true },
            { name: "count", luaGlobal: "CRAFT_COUNT", description: "How many to craft (default: 1)", required: false }
        ],
        examples: [
            "factorio craft iron-gear-wheel",
            "factorio craft electronic-circuit 10",
            "factorio craft automation-science-pack 5"
        ]
    },
    interact: {
        description: "Interact with nearby buildings",
        params: [
            { name: "action", luaGlobal: "ACTION", description: "insert, take, fuel, or check", required: true },
            { name: "entity", luaGlobal: "ENTITY_NAME", description: "Building type: stone-furnace, burner-mining-drill, etc.", required: true },
            { name: "item", luaGlobal: "ITEM_NAME", description: "Item to insert/take (for insert/take actions)", required: false },
            { name: "count", luaGlobal: "ITEM_COUNT", description: "How many items (default: 1)", required: false }
        ],
        examples: [
            "factorio interact check stone-furnace",
            "factorio interact insert stone-furnace coal 10",
            "factorio interact fuel burner-mining-drill",
            "factorio interact take stone-furnace iron-plate 20"
        ]
    },
    research: {
        description: "Manage technology research",
        params: [
            { name: "action", luaGlobal: "RESEARCH_ACTION", description: "status, available, start, or cancel", required: true },
            { name: "technology", luaGlobal: "TECHNOLOGY", description: "Technology name (for start action)", required: false }
        ],
        examples: [
            "factorio research status",
            "factorio research available",
            "factorio research start automation",
            "factorio research cancel"
        ]
    }
};

// Special commands that don't use Lua tools
const SPECIAL_COMMANDS = ["screenshot", "say", "help"];

function log(file: string, message: string) {
    const timestamp = new Date().toISOString();
    const logPath = path.join(logsDir, file);
    fs.appendFileSync(logPath, `${timestamp} | ${message}\n`);
}

function logUsage(command: string, args: string[], result: string) {
    const argsStr = args.join(" ");
    log("tool-usage.log", `${command} | ${argsStr} | ${result}`);
}

function logError(command: string, args: string[], error: string) {
    const argsStr = args.join(" ");
    log("tool-errors.log", `${command} | ${argsStr} | ${error}`);
}

function showHelp() {
    console.log("Factorio CLI - Your interface to play Factorio\n");
    console.log("Usage: factorio <command> [args...]\n");
    console.log("Commands:");
    for (const [name, tool] of Object.entries(TOOLS)) {
        console.log(`  ${name.padEnd(12)} ${tool.description}`);
    }
    console.log(`  screenshot   Take a screenshot`);
    console.log(`  say          Send a chat message`);
    console.log("\nRun 'factorio <command> --help' for command-specific help.");
}

function showCommandHelp(command: string) {
    const tool = TOOLS[command];
    if (!tool) {
        console.error(`Unknown command: ${command}`);
        process.exit(1);
    }

    console.log(`factorio ${command} - ${tool.description}\n`);
    console.log("Parameters:");
    for (const param of tool.params) {
        const req = param.required ? "(required)" : "(optional)";
        console.log(`  ${param.name.padEnd(15)} ${param.description} ${req}`);
    }
    console.log("\nExamples:");
    for (const ex of tool.examples) {
        console.log(`  ${ex}`);
    }
}

async function runLuaTool(toolName: string, args: string[]): Promise<{ success: boolean; output: string }> {
    const tool = TOOLS[toolName];
    if (!tool) {
        return { success: false, output: `Unknown tool: ${toolName}` };
    }

    const toolPath = path.join(luaApiDir, `${toolName}.lua`);
    if (!fs.existsSync(toolPath)) {
        return { success: false, output: `Tool file not found: ${toolPath}` };
    }

    // Build parameter assignments
    const paramAssignments: string[] = [];
    for (let i = 0; i < args.length && i < tool.params.length; i++) {
        const param = tool.params[i];
        let value = args[i];

        // If value is a number, don't quote it
        if (/^-?\d+(\.\d+)?$/.test(value)) {
            paramAssignments.push(`${param.luaGlobal} = ${value}`);
        } else {
            paramAssignments.push(`${param.luaGlobal} = "${value}"`);
        }
    }

    // Read and modify the Lua code
    let luaCode = fs.readFileSync(toolPath, "utf-8");

    if (paramAssignments.length > 0) {
        const assignStr = paramAssignments.join("; ");
        const iifeStart = luaCode.indexOf("(function()");
        if (iifeStart !== -1) {
            luaCode = luaCode.substring(0, iifeStart) + assignStr + ";\n" + luaCode.substring(iifeStart);
        } else {
            luaCode = assignStr + ";\n" + luaCode;
        }
    }

    // Wrap result in rcon.print
    luaCode = luaCode.trimEnd();
    if (luaCode.endsWith("end)()")) {
        const iifeStart = luaCode.lastIndexOf("(function()");
        if (iifeStart !== -1) {
            const before = luaCode.substring(0, iifeStart);
            const iife = luaCode.substring(iifeStart);
            luaCode = before + "rcon.print(serpent.line(" + iife + "))";
        }
    }

    // Run via factorio-eval
    const evalScript = path.join(projectRoot, "scripts", "factorio-eval.ts");

    return new Promise((resolve) => {
        const child = spawn("tsx", [evalScript, luaCode], {
            cwd: projectRoot,
            stdio: ["pipe", "pipe", "pipe"]
        });

        let stdout = "";
        let stderr = "";

        child.stdout.on("data", (data) => { stdout += data; });
        child.stderr.on("data", (data) => { stderr += data; });

        child.on("close", (code) => {
            const output = stdout.trim() || stderr.trim();
            resolve({
                success: code === 0,
                output
            });
        });
    });
}

function runScreenshot(suffix?: string): { success: boolean; output: string } {
    const args = suffix ? [suffix] : [];
    const result = spawnSync(path.join(projectRoot, "scripts", "take-screenshot.sh"), args, {
        cwd: projectRoot,
        stdio: ["pipe", "pipe", "pipe"]
    });
    return {
        success: result.status === 0,
        output: result.stdout?.toString().trim() || result.stderr?.toString().trim() || ""
    };
}

function runSay(message: string): { success: boolean; output: string } {
    const sayScript = path.join(projectRoot, "scripts", "factorio-say.ts");
    const result = spawnSync("tsx", [sayScript, message], {
        cwd: projectRoot,
        stdio: ["pipe", "pipe", "pipe"]
    });
    return {
        success: result.status === 0,
        output: result.stdout?.toString().trim() || result.stderr?.toString().trim() || ""
    };
}

async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
        showHelp();
        process.exit(0);
    }

    const command = args[0];
    const commandArgs = args.slice(1);

    // Check for command-specific help
    if (commandArgs.includes("--help") || commandArgs.includes("-h")) {
        if (TOOLS[command]) {
            showCommandHelp(command);
        } else if (command === "screenshot") {
            console.log("factorio screenshot [suffix] - Take a screenshot\n");
            console.log("Examples:");
            console.log("  factorio screenshot");
            console.log("  factorio screenshot base-overview");
        } else if (command === "say") {
            console.log("factorio say <message> - Send a chat message\n");
            console.log("Examples:");
            console.log("  factorio say \"Hello world\"");
            console.log("  factorio say \"Mining iron ore now\"");
        } else {
            console.error(`Unknown command: ${command}`);
            process.exit(1);
        }
        process.exit(0);
    }

    let result: { success: boolean; output: string };

    // Handle special commands
    if (command === "screenshot") {
        result = runScreenshot(commandArgs[0]);
        console.log(result.output);
        logUsage("screenshot", commandArgs, result.success ? "success" : "error");
        if (!result.success) logError("screenshot", commandArgs, result.output);
        process.exit(result.success ? 0 : 1);
    }

    if (command === "say") {
        const message = commandArgs.join(" ");
        if (!message) {
            console.error("Usage: factorio say <message>");
            process.exit(1);
        }
        result = runSay(message);
        console.log(result.output);
        logUsage("say", commandArgs, result.success ? "success" : "error");
        if (!result.success) logError("say", commandArgs, result.output);
        process.exit(result.success ? 0 : 1);
    }

    // Handle Lua tools
    if (!TOOLS[command]) {
        console.error(`Unknown command: ${command}`);
        console.error("Run 'factorio --help' for available commands.");
        process.exit(1);
    }

    result = await runLuaTool(command, commandArgs);
    console.log(result.output);

    logUsage(command, commandArgs, result.success ? "success" : "error");
    if (!result.success) {
        logError(command, commandArgs, result.output);
    }

    process.exit(result.success ? 0 : 1);
}

main();
