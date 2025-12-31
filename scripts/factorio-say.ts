#!/usr/bin/env tsx
/**
 * Factorio Chat Script
 *
 * Sends a message to the Factorio game chat via RCON.
 * Used by the AI agent to respond to players.
 *
 * Usage:
 *   pnpm say "Hello, I'm building iron gear wheels!"
 */

import "dotenv/config";
import { Rcon } from "rcon-ts";

const RCON_HOST = process.env.FACTORIO_RCON_HOST ?? "localhost";
const RCON_PORT = parseInt(process.env.FACTORIO_RCON_PORT ?? "27015", 10);
const RCON_PASSWORD = process.env.FACTORIO_RCON_PASSWORD ?? "";

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function escapeForLua(str: string): string {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r");
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
  const message = process.argv[2];

  if (!message) {
    console.error("Usage: pnpm say <message>");
    console.error("");
    console.error("Examples:");
    console.error('  pnpm say "Hello! I am building a factory."');
    console.error('  pnpm say "I need more iron ore, heading to the patch now."');
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
    const escapedMessage = escapeForLua(message);
    // Use game.print with a distinct AI prefix
    const command = `/silent-command game.print("[color=0.3,1,0.3][AI Chat][/color] ${escapedMessage}")`;

    await executeWithRetry(rcon, command);
    console.log(`Sent: ${message}`);
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
