#!/usr/bin/env tsx
/**
 * Run a Lua file in Factorio via RCON
 * Usage: pnpm eval:file <path-to-lua-file>
 *
 * Simply reads the file and passes it to the main eval script.
 */

import * as fs from "fs";
import { spawn } from "child_process";
import * as path from "path";

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
