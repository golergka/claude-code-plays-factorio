#!/usr/bin/env tsx
/**
 * Factorio Lua Evaluation Script
 *
 * Sends Lua code to Factorio via RCON and returns the result.
 * The code is wrapped with rcon.print() to return output.
 *
 * Usage:
 *   pnpm eval "game.player.position"
 *   pnpm eval "game.player.get_main_inventory().get_contents()"
 *   echo "game.tick" | pnpm eval
 *
 * For structured data, the script automatically wraps results with serpent.line()
 * unless the code already contains rcon.print().
 */

import "dotenv/config";
import { Rcon } from "rcon-ts";

const RCON_HOST = process.env.FACTORIO_RCON_HOST ?? "localhost";
const RCON_PORT = parseInt(process.env.FACTORIO_RCON_PORT ?? "27015", 10);
const RCON_PASSWORD = process.env.FACTORIO_RCON_PASSWORD ?? "";
// Player name or index for multiplayer - defaults to player index 1
const PLAYER_TARGET = process.env.FACTORIO_PLAYER ?? "1";

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;

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

function wrapLuaCode(code: string): string {
  const playerAccessor = getPlayerAccessor();

  // Inject a 'player' variable pointing to the target player
  // This allows code to use 'player' instead of 'game.player'
  const playerSetup = `local player = ${playerAccessor}; local surface = player.surface; local force = player.force; `;

  // If the code already uses rcon.print, just inject player variable
  if (code.includes("rcon.print")) {
    return playerSetup + code;
  }

  // Wrap the code to return its result via rcon.print with serpent serialization
  // We use serpent.line for compact, parseable output
  return `${playerSetup}rcon.print(serpent.line((function() return ${code} end)()))`;
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
    console.error("The script injects 'player', 'surface', and 'force' variables automatically.");
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
    console.error("Error: FACTORIO_RCON_PASSWORD environment variable not set");
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

    // Output the result
    if (result) {
      console.log(result);
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
