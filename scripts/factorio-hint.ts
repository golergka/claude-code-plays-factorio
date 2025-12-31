#!/usr/bin/env tsx
/**
 * Factorio Agent Hint Script
 *
 * Writes a hint to the hints file for the agent to read.
 * Hints are read once by factorio-eval.ts and then cleared.
 *
 * Usage:
 *   pnpm hint "Focus on building a burner drill on coal"
 */

import * as fs from "fs";
import * as path from "path";
import * as os from "os";

const HINTS_FILE = path.join(os.tmpdir(), "factorio-agent-hints.txt");

async function main(): Promise<void> {
  const hint = process.argv[2];

  if (!hint) {
    console.error("Usage: pnpm hint <message>");
    console.error("");
    console.error("Examples:");
    console.error('  pnpm hint "Focus on building automation"');
    console.error('  pnpm hint "You have iron plates, try crafting gear wheels"');
    process.exit(1);
  }

  try {
    // Append hint to file (in case multiple hints are sent before next eval)
    fs.appendFileSync(HINTS_FILE, hint + "\n");
    console.log(`Hint queued: ${hint}`);
  } catch (error) {
    if (error instanceof Error) {
      console.error(`Error writing hint: ${error.message}`);
    } else {
      console.error("Error writing hint:", error);
    }
    process.exit(1);
  }
}

main();
