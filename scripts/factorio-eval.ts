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
// Max length for output results (0 = no limit)
const MAX_OUTPUT_LENGTH = parseInt(
  process.env.FACTORIO_MAX_OUTPUT_LENGTH ?? "4000",
  10
);
// Path to Factorio server log for reading chat
const FACTORIO_LOG_PATH =
  process.env.FACTORIO_LOG_PATH ?? getDefaultLogPath();
// State file to track last read position
const STATE_FILE = path.join(os.tmpdir(), "factorio-agent-chat-state.json");

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

function wrapLuaCode(code: string): string {
  const playerAccessor = getPlayerAccessor();

  // Check if the code uses player/surface/force variables
  const needsPlayer = /\b(player|surface|force)\b/.test(code);

  // Inject player variables only if needed
  let playerSetup = "";
  if (needsPlayer) {
    playerSetup = `local player = ${playerAccessor}; if not player then rcon.print("ERROR: No player connected yet. Connect to the server first."); return end; local surface = player.surface; local force = player.force; `;
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
    const wrappedCode = wrapLuaCode(luaCode);
    const command = `/silent-command ${wrappedCode}`;

    const result = await executeWithRetry(rcon, command);

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
      if (MAX_OUTPUT_LENGTH > 0 && result.length > MAX_OUTPUT_LENGTH) {
        console.log(result.substring(0, MAX_OUTPUT_LENGTH));
        console.log(`\n... [OUTPUT TRUNCATED - ${result.length} chars total, showing first ${MAX_OUTPUT_LENGTH}]`);
      } else {
        console.log(result);
      }
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
