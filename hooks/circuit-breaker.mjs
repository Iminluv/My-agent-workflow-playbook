#!/usr/bin/env node

/**
 * circuit-breaker.mjs
 * 
 * Antigravity Lifecycle PreToolUse Hook
 * Mechanically enforces Rule 9 of GEMINI.md & Rule 1.2 of core-protocol.md:
 * "Never execute more than 4 consecutive tool calls without outputting visible interim progress text to the user."
 * 
 * Target: Intercepts all tool calls ("matcher": "*").
 * Logic:
 *  - Reads recent transcript entries via tail reading.
 *  - Counts consecutive tool calls since the last user-facing model message.
 *  - Blocks the 5th consecutive silent tool call with an informative reason.
 *  - Resets count to 1 as soon as the model outputs text.
 *  - Fails open gracefully on any I/O error or missing transcript.
 */

import process from 'node:process';
import fs from 'node:fs';

const MAX_CONSECUTIVE_SILENT_TOOLS = 4;

function readStdin() {
  return new Promise((resolve, reject) => {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => {
      input += chunk;
      if (input.length > 1024 * 1024) {
        reject(new Error('hook payload exceeds 1 MiB'));
      }
    });
    process.stdin.on('end', () => resolve(input));
    process.stdin.on('error', reject);
  });
}

function readLastTranscriptLines(filePath, maxLines = 50) {
  try {
    if (!filePath || !fs.existsSync(filePath)) return [];
    const stat = fs.statSync(filePath);
    const bufferSize = Math.min(stat.size, 64 * 1024);
    const fd = fs.openSync(filePath, 'r');
    const buffer = Buffer.alloc(bufferSize);
    fs.readSync(fd, buffer, 0, bufferSize, stat.size - bufferSize);
    fs.closeSync(fd);

    const text = buffer.toString('utf8');
    const lines = text.split('\n').filter(l => l.trim().length > 0);
    const parsed = [];
    for (let i = Math.max(0, lines.length - maxLines); i < lines.length; i++) {
      try {
        parsed.push(JSON.parse(lines[i]));
      } catch {
        // ignore truncated boundary line
      }
    }
    return parsed;
  } catch {
    return [];
  }
}

function evaluateCircuitBreaker(history, currentStepIdx, maxLimit = MAX_CONSECUTIVE_SILENT_TOOLS) {
  let silentTools = 0;
  let currentStepRecorded = false;

  for (let i = history.length - 1; i >= 0; i--) {
    const entry = history[i];
    if (entry.step_index === currentStepIdx) {
      currentStepRecorded = true;
    }
    if (entry.type === 'USER_INPUT') {
      break;
    }
    if (entry.type === 'PLANNER_RESPONSE' && entry.source === 'MODEL') {
      const text = (entry.content || '').trim();
      const toolCalls = (entry.tool_calls || []).length;
      if (text.length > 0) {
        silentTools += toolCalls;
        break;
      } else {
        silentTools += toolCalls;
      }
    }
  }

  const projectedCount = currentStepRecorded ? silentTools : silentTools + 1;

  if (projectedCount > maxLimit) {
    return {
      allowed: false,
      count: projectedCount,
      reason: `🚨 ANTI-SILENT CIRCUIT BREAKER BLOCKED: You have reached ${projectedCount} consecutive tool calls without providing interim progress text to the user (strict ceiling is ${maxLimit}). Per Rule 9 of GEMINI.md, you MUST emit visible interim progress text to the user before calling another tool.`
    };
  }

  return {
    allowed: true,
    count: projectedCount
  };
}

async function main() {
  let raw = '';
  try {
    raw = await readStdin();
  } catch {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }

  let payload = {};
  try {
    payload = JSON.parse(raw || '{}');
  } catch {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }

  const transcriptPath = payload.transcriptPath;
  const stepIdx = payload.stepIdx;

  if (!transcriptPath) {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }

  try {
    const history = readLastTranscriptLines(transcriptPath, 40);
    if (!history || history.length === 0) {
      process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
      return 0;
    }

    const result = evaluateCircuitBreaker(history, stepIdx, MAX_CONSECUTIVE_SILENT_TOOLS);
    if (!result.allowed) {
      process.stdout.write(JSON.stringify({
        decision: 'deny',
        reason: result.reason
      }) + '\n');
      return 0;
    }

    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  } catch {
    // Fail open safely on unexpected errors
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  await main();
}
