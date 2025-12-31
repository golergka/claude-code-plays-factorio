#!/usr/bin/env tsx
/**
 * Run a Lua file in Factorio via RCON
 * Usage: pnpm eval:file <path-to-lua-file>
 */

import "dotenv/config";
import { Rcon } from "rcon-ts";
import * as fs from "fs";

const RCON_HOST = process.env.FACTORIO_RCON_HOST ?? "localhost";
const RCON_PORT = parseInt(process.env.FACTORIO_RCON_PORT ?? "27015", 10);
const RCON_PASSWORD = process.env.FACTORIO_RCON_PASSWORD ?? "";
const PLAYER_TARGET = process.env.FACTORIO_PLAYER ?? "1";

function getPlayerAccessor(): string {
  const isIndex = /^\d+$/.test(PLAYER_TARGET);
  return isIndex ? `game.players[${PLAYER_TARGET}]` : `game.players["${PLAYER_TARGET}"]`;
}

async function main(): Promise<void> {
  const filePath = process.argv[2];

  if (!filePath) {
    console.error("Usage: pnpm eval:file <lua-file>");
    process.exit(1);
  }

  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(1);
  }

  const luaCode = fs.readFileSync(filePath, "utf-8");

  // Inject player variables
  const playerAccessor = getPlayerAccessor();
  const wrappedCode = `
    local player = ${playerAccessor}
    if not player then rcon.print("ERROR: No player"); return end
    local surface = player.surface
    local force = player.force
    ${luaCode}
  `;

  const rcon = new Rcon({
    host: RCON_HOST,
    port: RCON_PORT,
    password: RCON_PASSWORD,
  });

  try {
    await rcon.connect();
    const result = await rcon.send(`/silent-command ${wrappedCode}`);
    await rcon.disconnect();
    if (result) console.log(result);
  } catch (error) {
    console.error("RCON Error:", error);
    process.exit(1);
  }
}

main();
