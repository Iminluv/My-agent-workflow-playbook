#!/usr/bin/env node

import fs from 'node:fs';
import process from 'node:process';
import { pathToFileURL } from 'node:url';

const BLOCK_RULES = [
  {
    id: 'unix-root-delete',
    pattern: /(?:^|[;&|]\s*)(?:sudo\s+)?rm\s+(?:-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*)\s+(?:--\s+)?\/(?:\*|\s|$)/i,
    message: 'recursive deletion of the filesystem root'
  },
  {
    id: 'filesystem-format',
    pattern: /(?:^|[;&|]\s*)(?:sudo\s+)?mkfs(?:\.[A-Za-z0-9_-]+)?\b/i,
    message: 'filesystem formatting command'
  },
  {
    id: 'raw-disk-overwrite',
    pattern: /\bdd\b[^\n]*\bof=\/dev\/(?:sd|nvme|vd|xvd)[A-Za-z0-9_-]*/i,
    message: 'raw disk overwrite'
  },
  {
    id: 'windows-drive-format',
    pattern: /(?:^|[;&|]\s*)format(?:\.com)?\s+[A-Za-z]:/i,
    message: 'Windows drive format'
  },
  {
    id: 'windows-root-delete',
    pattern: /remove-item\b[^\n]*-(?:recurse|r)\b[^\n]*-(?:force|fo)\b[^\n]*(?:[A-Za-z]:\\(?:\s|$)|[A-Za-z]:\\\*)/i,
    message: 'recursive deletion of a Windows drive root'
  }
];

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

function firstString(...values) {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

export function extractCommand(payload) {
  const args = payload?.toolCall?.args ?? payload?.tool_args ?? payload?.toolArgs ?? payload?.arguments ?? {};
  return firstString(
    args.CommandLine,
    args.commandLine,
    args.command,
    args.cmd,
    payload?.command,
    payload?.cmd
  );
}

export function evaluateCommand(command) {
  for (const rule of BLOCK_RULES) {
    if (rule.pattern.test(command)) {
      return {allowed: false, rule: rule.id, reason: rule.message};
    }
  }
  return {allowed: true, rule: null, reason: 'no destructive command pattern matched'};
}

async function main() {
  let raw = '';
  try {
    raw = await readStdin();
  } catch (error) {
    console.error(`AG Kit hook warning: ${error.message}`);
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

  const command = extractCommand(payload);
  if (!command) {
    process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
    return 0;
  }

  const result = evaluateCommand(command);
  if (!result.allowed) {
    process.stdout.write(JSON.stringify({
      decision: 'deny',
      reason: `BLOCKED by AG Kit (${result.rule}): ${result.reason}`
    }) + '\n');
    return 0;
  }

  process.stdout.write(JSON.stringify({ decision: 'allow' }) + '\n');
  return 0;
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
