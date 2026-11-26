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
 *  - Counts consecutive tool calls since the last user-facing model message or USER_INPUT.
 *  - Accounts for Antigravity transcript timing where PLANNER_RESPONSE (step K, N tool_calls)
 *    is recorded before PreToolUse fires for its GENERIC child steps [K+1 .. K+N].
 *  - Excludes prior GENERIC entries with status === "ERROR" so denied/errored calls do not inflate counts.
 *  - Blocks the 5th consecutive silent tool call with an informative reason.
 *  - Fails open gracefully on any I/O error or missing transcript.
 */

import process from 'node:process';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

export const MAX_CONSECUTIVE_SILENT_TOOLS = 4;

const MAX_PAYLOAD_BYTES = 1024 * 1024;
const TAIL_BUFFER_BYTES = 256 * 1024;
const DEFAULT_TAIL_LINES = 80;

function readStdin() {
  return new Promise((resolve, reject) => {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => {
      input += chunk;
      if (input.length > MAX_PAYLOAD_BYTES) {
        reject(new Error('hook payload exceeds 1 MiB'));
      }
    });
    process.stdin.on('end', () => resolve(input));
    process.stdin.on('error', reject);
  });
}

export function readLastTranscriptLines(filePath, maxLines = DEFAULT_TAIL_LINES) {
  try {
    if (!filePath || !fs.existsSync(filePath)) return [];
    const stat = fs.statSync(filePath);
    const bufferSize = Math.min(stat.size, TAIL_BUFFER_BYTES);
    if (bufferSize <= 0) return [];

    const fd = fs.openSync(filePath, 'r');
    const buffer = Buffer.alloc(bufferSize);
    try {
      fs.readSync(fd, buffer, 0, bufferSize, stat.size - bufferSize);
    } finally {
      fs.closeSync(fd);
    }

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

function isFiniteNumber(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

function extractTextContent(content) {
  if (typeof content === 'string') {
    return content.trim();
  }
  if (Array.isArray(content)) {
    return content
      .map(part => (typeof part === 'string' ? part : typeof part?.text === 'string' ? part.text : ''))
      .join('')
      .trim();
  }
  return '';
}

export function evaluateCircuitBreaker(history, currentStepIdx, maxLimit = MAX_CONSECUTIVE_SILENT_TOOLS) {
  if (!Array.isArray(history) || history.length === 0) {
    const count = 1;
    if (count > maxLimit) {
      return {
        allowed: false,
        count,
        reason: `🚨 ANTI-SILENT CIRCUIT BREAKER BLOCKED: You have reached ${count} consecutive tool calls without providing interim progress text to the user (strict ceiling is ${maxLimit}). Per Rule 9 of GEMINI.md, you MUST emit visible interim progress text to the user before calling another tool.`
      };
    }
    return { allowed: true, count };
  }

  let silentTools = 0;
  let currentStepCovered = false;
  const errorSteps = new Set();
  const hasCurrentIdx = isFiniteNumber(currentStepIdx);

  for (let i = history.length - 1; i >= 0; i--) {
    const entry = history[i];
    if (!entry || typeof entry !== 'object') {
      continue;
    }

    if (entry.type === 'USER_INPUT') {
      break;
    }

    if (entry.type === 'GENERIC') {
      if (entry.status === 'ERROR' && isFiniteNumber(entry.step_index)) {
        errorSteps.add(entry.step_index);
      }
      continue;
    }

    if (entry.type === 'PLANNER_RESPONSE' && entry.source === 'MODEL') {
      const text = extractTextContent(entry.content);
      const rawToolCalls = Array.isArray(entry.tool_calls) ? entry.tool_calls.length : 0;
      let effectiveToolCalls = rawToolCalls;

      if (isFiniteNumber(entry.step_index) && rawToolCalls > 0) {
        const spanStart = entry.step_index + 1;
        const spanEnd = entry.step_index + rawToolCalls;

        let erroredInSpan = 0;
        for (const errStep of errorSteps) {
          if (errStep !== currentStepIdx && errStep >= spanStart && errStep <= spanEnd) {
            erroredInSpan++;
          }
        }
        effectiveToolCalls = Math.max(0, rawToolCalls - erroredInSpan);

        if (
          hasCurrentIdx &&
          ((currentStepIdx >= spanStart && currentStepIdx <= spanEnd) ||
            currentStepIdx === entry.step_index)
        ) {
          currentStepCovered = true;
        }
      }

      silentTools += effectiveToolCalls;

      if (text.length > 0) {
        break;
      }
    }
  }

  const projectedCount = currentStepCovered ? silentTools : silentTools + 1;

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
  const stepIdx = payload.stepIdx ?? payload.step_index;

  if (!transcriptPath) {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }

  try {
    const history = readLastTranscriptLines(transcriptPath, DEFAULT_TAIL_LINES);
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

function isExecutedDirectly() {
  if (!process.argv[1]) return false;
  try {
    return import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href;
  } catch {
    return import.meta.url === `file://${process.argv[1]}`;
  }
}

if (isExecutedDirectly()) {
  await main();
}
