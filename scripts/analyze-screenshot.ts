#!/usr/bin/env tsx
/**
 * Analyze Factorio screenshots using OpenAI Vision API
 * Provides strategic hints and observations for the AI agent
 *
 * Usage: pnpm analyze
 */

import 'dotenv/config';
import OpenAI from 'openai';
import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const openai = new OpenAI();

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function takeScreenshot(): Promise<string> {
  const projectDir = path.resolve(__dirname, '..');
  const screenshotDir = path.join(
    process.env.HOME || '',
    'Library/Application Support/factorio/script-output'
  );

  // Get files before taking screenshot
  const beforeFiles = new Set(fs.readdirSync(screenshotDir));

  // Take screenshot using existing script
  try {
    execSync(`./scripts/take-screenshot.sh analysis`, { cwd: projectDir, stdio: 'pipe' });

    // Wait for the file to appear (game takes a moment to write)
    let newFile: string | null = null;
    for (let i = 0; i < 10; i++) {
      await sleep(500);
      const afterFiles = fs.readdirSync(screenshotDir);
      const newFiles = afterFiles.filter(f => !beforeFiles.has(f) && f.includes('analysis'));
      if (newFiles.length > 0) {
        newFile = newFiles[0];
        break;
      }
    }

    if (!newFile) {
      // Fallback to most recent analysis file
      const files = fs.readdirSync(screenshotDir)
        .filter(f => f.includes('analysis'))
        .sort()
        .reverse();
      if (files.length > 0) {
        newFile = files[0];
      }
    }

    if (!newFile) {
      throw new Error('No screenshot found after waiting');
    }

    return path.join(screenshotDir, newFile);
  } catch (error) {
    console.error('Failed to take screenshot:', error);
    process.exit(1);
  }
}

async function analyzeImage(imagePath: string): Promise<string> {
  const imageBuffer = fs.readFileSync(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const prompt = `You are analyzing a Factorio game screenshot to help an AI agent play the game.

Please analyze this screenshot and provide:

1. **Current State**: What buildings, resources, and entities do you see? Note any:
   - Mining drills (burner or electric)
   - Furnaces and their status
   - Assembling machines
   - Power setup (boilers, steam engines)
   - Resource patches (iron ore is blue, copper ore is orange/red, coal is black, stone is tan)

2. **Problems**: Are there any visible issues?
   - Idle machines (no smoke, yellow warning icons)
   - Blocked outputs
   - Depleted resources
   - Missing power connections
   - Fuel shortages

3. **Opportunities**: What should the agent focus on next?
   - Nearby resources to exploit
   - Expansion possibilities
   - Automation improvements

4. **Strategic Hints**: Specific actionable advice for the agent

Be concise but thorough. Focus on what's important for game progress.
The agent cannot see the game visually - it relies entirely on your analysis.`;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          {
            type: 'image_url',
            image_url: {
              url: `data:image/png;base64,${base64Image}`,
              detail: 'high'
            }
          }
        ]
      }
    ],
    max_tokens: 1000
  });

  return response.choices[0].message.content || 'No analysis available';
}

async function main() {
  console.log('Taking screenshot...');
  const imagePath = await takeScreenshot();
  console.log(`Screenshot: ${imagePath}`);

  console.log('Analyzing with OpenAI Vision...');
  const analysis = await analyzeImage(imagePath);

  console.log('\n=== SCREENSHOT ANALYSIS ===\n');
  console.log(analysis);
  console.log('\n=== END ANALYSIS ===\n');
}

main().catch(console.error);
