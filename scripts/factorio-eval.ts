#!/usr/bin/env tsx
/**
 * Factorio Lua Evaluation Script
 *
 * Sends Lua code to Factorio via RCON and returns the result.
 * Also monitors the server log for chat messages and includes them in output.
 *
 * Usage:
 *   pnpm eval "player.position"
 *   pnpm eval "player.get_main_inventory().get_contents()"
 *   echo "game.tick" | pnpm eval
 */

import "dotenv/config";
import { Rcon } from "rcon-ts";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

const RCON_HOST = process.env.FACTORIO_RCON_HOST ?? "localhost";
const RCON_PORT = parseInt(process.env.FACTORIO_RCON_PORT ?? "27015", 10);
const RCON_PASSWORD = process.env.FACTORIO_RCON_PASSWORD ?? "";
// Player name or index for multiplayer - defaults to player index 1
const PLAYER_TARGET = process.env.FACTORIO_PLAYER ?? "1";
// Show commands in game chat for streaming
const SHOW_COMMANDS = process.env.FACTORIO_SHOW_COMMANDS === "true";
// Max length for displayed commands (0 = no limit)
const MAX_DISPLAY_LENGTH = parseInt(
  process.env.FACTORIO_MAX_DISPLAY_LENGTH ?? "200",
  10
);
// Max length for string values in output (0 = no limit)
const MAX_STRING_LENGTH = parseInt(
  process.env.FACTORIO_MAX_STRING_LENGTH ?? "500",
  10
);
// Path to Factorio server log for reading chat
const FACTORIO_LOG_PATH =
  process.env.FACTORIO_LOG_PATH ?? getDefaultLogPath();
// State file to track last read position
const STATE_FILE = path.join(os.tmpdir(), "factorio-agent-chat-state.json");
// Hints file - supervisor writes here, we read and clear
const HINTS_FILE = path.join(os.tmpdir(), "factorio-agent-hints.txt");
// Proximity enforcement - if true, entity interactions require being close
const ENFORCE_PROXIMITY = process.env.FACTORIO_ENFORCE_PROXIMITY !== "false";
// Proximity enforcer Lua code
const PROXIMITY_ENFORCER_PATH = path.join(
  path.dirname(new URL(import.meta.url).pathname),
  "proximity-enforcer.lua"
);

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;

function getDefaultLogPath(): string {
  // Default log paths for different platforms
  if (process.platform === "darwin") {
    return path.join(
      os.homedir(),
      "Library/Application Support/factorio/factorio-current.log"
    );
  } else if (process.platform === "win32") {
    return path.join(
      process.env.APPDATA ?? "",
      "Factorio/factorio-current.log"
    );
  } else {
    return path.join(os.homedir(), ".factorio/factorio-current.log");
  }
}

interface ChatState {
  lastPosition: number;
  lastModified: number;
}

interface ChatMessage {
  timestamp: string;
  player: string;
  message: string;
}

function loadChatState(): ChatState {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, "utf-8"));
    }
  } catch {
    // Ignore errors, start fresh
  }
  return { lastPosition: 0, lastModified: 0 };
}

function saveChatState(state: ChatState): void {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(state));
  } catch {
    // Ignore errors
  }
}

/**
 * Read hints from file and clear it (so hints are only shown once)
 */
function readAndClearHints(): string[] {
  const hints: string[] = [];

  if (!fs.existsSync(HINTS_FILE)) {
    return hints;
  }

  try {
    const content = fs.readFileSync(HINTS_FILE, "utf-8").trim();
    if (content) {
      hints.push(...content.split("\n").filter((line) => line.trim()));
    }
    // Clear the file after reading
    fs.writeFileSync(HINTS_FILE, "");
  } catch {
    // Ignore errors
  }

  return hints;
}

function readNewChatMessages(): ChatMessage[] {
  const messages: ChatMessage[] = [];

  if (!fs.existsSync(FACTORIO_LOG_PATH)) {
    return messages;
  }

  try {
    const stats = fs.statSync(FACTORIO_LOG_PATH);
    const state = loadChatState();

    // If file was modified or rotated, read from appropriate position
    let startPosition = state.lastPosition;
    if (stats.mtimeMs < state.lastModified || stats.size < state.lastPosition) {
      // Log was rotated, start from beginning
      startPosition = 0;
    }

    // Read the file from last position
    const fd = fs.openSync(FACTORIO_LOG_PATH, "r");
    const buffer = Buffer.alloc(stats.size - startPosition);
    fs.readSync(fd, buffer, 0, buffer.length, startPosition);
    fs.closeSync(fd);

    const content = buffer.toString("utf-8");
    const lines = content.split("\n");

    // Parse chat messages - format: "   0.000 [CHAT] PlayerName: message"
    // or "[CHAT] PlayerName: message"
    const chatRegex = /^(?:\s*[\d.]+\s+)?\[CHAT\]\s+([^:]+):\s*(.+)$/;

    for (const line of lines) {
      const match = line.match(chatRegex);
      if (match) {
        const [, player, message] = match;
        // Skip messages from the AI itself (our own prints)
        // These include [AI] for commands and [AI Chat] for responses
        if (!message.startsWith("[AI]") && !message.startsWith("[AI Chat]")) {
          messages.push({
            timestamp: new Date().toISOString(),
            player: player.trim(),
            message: message.trim(),
          });
        }
      }
    }

    // Save new position
    saveChatState({
      lastPosition: stats.size,
      lastModified: stats.mtimeMs,
    });
  } catch {
    // Ignore errors reading log
  }

  return messages;
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf-8").trim();
}

function getPlayerAccessor(): string {
  // If it's a number, access by index; otherwise by name
  const isIndex = /^\d+$/.test(PLAYER_TARGET);
  if (isIndex) {
    return `game.players[${PLAYER_TARGET}]`;
  }
  return `game.players["${PLAYER_TARGET}"]`;
}

function escapeForLua(str: string): string {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r");
}

function truncateCode(code: string): string {
  if (MAX_DISPLAY_LENGTH > 0 && code.length > MAX_DISPLAY_LENGTH) {
    return code.substring(0, MAX_DISPLAY_LENGTH) + "...";
  }
  return code;
}

/**
 * Truncate long string values in output.
 * Works with Lua serpent.line() output format (strings are "quoted").
 */
function truncateOutput(output: string): string {
  if (!output || MAX_STRING_LENGTH <= 0) return output;

  // Find quoted strings and truncate if too long
  // Matches "string content" while handling escaped quotes
  return output.replace(/"([^"\\]|\\.)*"/g, (match) => {
    // Remove quotes to get actual length
    const content = match.slice(1, -1);
    if (content.length > MAX_STRING_LENGTH) {
      const truncated = content.substring(0, MAX_STRING_LENGTH);
      return `"${truncated}..."`;
    }
    return match;
  });
}

// Load proximity enforcer code
function loadProximityEnforcer(): string {
  if (!ENFORCE_PROXIMITY) return "";
  try {
    return fs.readFileSync(PROXIMITY_ENFORCER_PATH, "utf-8");
  } catch {
    console.error("Warning: Could not load proximity enforcer");
    return "";
  }
}

// Pattern checking removed - proximity enforcement now handled dynamically in Lua
// The proximity-enforcer.lua intercepts entity methods at runtime

function wrapLuaCode(code: string): string {
  const playerAccessor = getPlayerAccessor();

  // Check if the code uses player/surface/force variables
  const needsPlayer = /\b(player|surface|force)\b/.test(code);

  // Inject player variables only if needed
  let playerSetup = "";
  if (needsPlayer) {
    playerSetup = `local player = ${playerAccessor}; if not player then rcon.print("ERROR: No player connected yet. Connect to the server first."); return end; local surface = player.surface; local force = player.force; `;

    // Inject proximity enforcement if enabled
    if (ENFORCE_PROXIMITY) {
      const enforcer = loadProximityEnforcer();
      if (enforcer) {
        playerSetup += enforcer + " ";
      }
    }
  }

  // Optionally show the command in game chat (for streaming)
  let displayCode = "";
  if (SHOW_COMMANDS && needsPlayer) {
    const escapedCode = escapeForLua(truncateCode(code));
    // Use game.print with colored text
    displayCode = `game.print("[color=0.5,0.8,1][AI][/color] ${escapedCode}"); `;
  }

  // If the code already uses rcon.print, just inject player variable and display
  if (code.includes("rcon.print")) {
    return playerSetup + displayCode + code;
  }

  // Wrap the code to return its result via rcon.print with serpent serialization
  // We use serpent.line for compact, parseable output
  return `${playerSetup}${displayCode}rcon.print(serpent.line((function() return ${code} end)()))`;
}

async function executeWithRetry(
  rcon: Rcon,
  command: string,
  retries: number = MAX_RETRIES
): Promise<string> {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      await rcon.connect();
      const result = await rcon.send(command);
      await rcon.disconnect();
      return result;
    } catch (error) {
      if (attempt === retries) {
        throw error;
      }
      console.error(
        `Connection attempt ${attempt} failed, retrying in ${RETRY_DELAY_MS}ms...`
      );
      await sleep(RETRY_DELAY_MS);
    }
  }
  throw new Error("Max retries exceeded");
}

async function main(): Promise<void> {
  // Get Lua code from command line argument or stdin
  let luaCode = process.argv[2];

  if (!luaCode) {
    // Try to read from stdin
    if (!process.stdin.isTTY) {
      luaCode = await readStdin();
    }
  }

  if (!luaCode) {
    console.error("Usage: pnpm eval <lua_code>");
    console.error("   or: echo <lua_code> | pnpm eval");
    console.error("");
    console.error(
      "The script injects 'player', 'surface', and 'force' variables automatically."
    );
    console.error(`Currently targeting: ${getPlayerAccessor()}`);
    console.error("");
    console.error("Examples:");
    console.error('  pnpm eval "player.position"');
    console.error('  pnpm eval "player.get_main_inventory().get_contents()"');
    console.error(
      '  pnpm eval "surface.find_entities_filtered{position=player.position, radius=10, type=\\"resource\\"}"'
    );
    process.exit(1);
  }

  if (!RCON_PASSWORD) {
    console.error(
      "Error: FACTORIO_RCON_PASSWORD environment variable not set"
    );
    console.error("Copy .env.example to .env and configure your RCON password");
    process.exit(1);
  }

  const rcon = new Rcon({
    host: RCON_HOST,
    port: RCON_PORT,
    password: RCON_PASSWORD,
  });

  try {
    // Proximity enforcement is handled dynamically in Lua via method interception
    const wrappedCode = wrapLuaCode(luaCode);
    const command = `/silent-command ${wrappedCode}`;

    const result = await executeWithRetry(rcon, command);

    // Check for supervisor hints (read and clear so they only appear once)
    const hints = readAndClearHints();
    if (hints.length > 0) {
      console.log("=== SUPERVISOR HINTS ===");
      for (const hint of hints) {
        console.log(`> ${hint}`);
      }
      console.log("=== END HINTS ===");
      console.log("");
    }

    // Check for new chat messages
    const chatMessages = readNewChatMessages();

    // Output chat messages first if any
    if (chatMessages.length > 0) {
      console.log("=== NEW CHAT MESSAGES ===");
      for (const msg of chatMessages) {
        console.log(`[${msg.player}]: ${msg.message}`);
      }
      console.log("=== END CHAT ===");
      console.log("");
    }

    // Output the command result (truncated if too long)
    if (result) {
      const truncated = truncateOutput(result);
      console.log(truncated);
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(`RCON Error: ${error.message}`);
    } else {
      console.error("RCON Error:", error);
    }
    process.exit(1);
  }
}

main();
