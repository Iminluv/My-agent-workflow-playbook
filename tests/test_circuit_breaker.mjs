import { describe, it, after } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  MAX_CONSECUTIVE_SILENT_TOOLS,
  readLastTranscriptLines,
  evaluateCircuitBreaker
} from '../hooks/circuit-breaker.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');
const HOOK_PATH = path.join(REPO_ROOT, 'hooks', 'circuit-breaker.mjs');

const tempDirs = [];

function createTempDir(prefix = 'ag-cb-test-') {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  tempDirs.push(dir);
  return dir;
}

function writeJsonlTranscript(dir, filename, entries) {
  const filePath = path.join(dir, filename);
  const content = entries.map(entry => (typeof entry === 'string' ? entry : JSON.stringify(entry))).join('\n') + '\n';
  fs.writeFileSync(filePath, content, 'utf8');
  return filePath;
}

function runHookCli(scriptPath, payload) {
  const input = typeof payload === 'string' ? payload : JSON.stringify(payload);
  const stdout = execFileSync(process.execPath, [scriptPath], {
    input,
    encoding: 'utf8',
    timeout: 10_000
  });
  return JSON.parse(stdout.trim());
}

after(() => {
  for (const dir of tempDirs) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

describe('circuit-breaker unit evaluation (evaluateCircuitBreaker)', () => {
  it('exports MAX_CONSECUTIVE_SILENT_TOOLS as 4', () => {
    assert.equal(MAX_CONSECUTIVE_SILENT_TOOLS, 4);
  });

  it('allows turn with visible text and 4 parallel tool calls across child steps 2..5', () => {
    const history = [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Inspecting workspace files in parallel.',
        tool_calls: [
          { id: 't1' },
          { id: 't2' },
          { id: 't3' },
          { id: 't4' }
        ]
      }
    ];

    for (const currentStepIdx of [2, 3, 4, 5]) {
      const result = evaluateCircuitBreaker(history, currentStepIdx);
      assert.equal(result.allowed, true, `expected step ${currentStepIdx} to be allowed`);
      assert.equal(result.count, 4);
    }
  });

  it('allows up to 4 consecutive tool calls across turns and denies the 5th silent call', () => {
    const historyThrough4 = [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Starting task with step 1.',
        tool_calls: [{ id: 't1' }]
      },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 3,
        content: '',
        tool_calls: [{ id: 't2' }]
      },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 5,
        content: '',
        tool_calls: [{ id: 't3' }]
      },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: 't4' }]
      }
    ];

    // 4th tool call covered by PLANNER_RESPONSE at step_index 7
    const fourthCovered = evaluateCircuitBreaker(historyThrough4, 8);
    assert.equal(fourthCovered.allowed, true);
    assert.equal(fourthCovered.count, 4);

    // 4th tool call evaluated before PLANNER_RESPONSE at step_index 7 is written
    const fourthUncovered = evaluateCircuitBreaker(historyThrough4.slice(0, 6), 7);
    assert.equal(fourthUncovered.allowed, true);
    assert.equal(fourthUncovered.count, 4);

    // 5th silent tool call (covered by silent PLANNER_RESPONSE at step_index 9) -> denied
    const historyThrough5 = [
      ...historyThrough4,
      { type: 'GENERIC', step_index: 8, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 9,
        content: '',
        tool_calls: [{ id: 't5' }]
      }
    ];

    const fifthDenied = evaluateCircuitBreaker(historyThrough5, 10);
    assert.equal(fifthDenied.allowed, false);
    assert.equal(fifthDenied.count, 5);
    assert.match(fifthDenied.reason, /ANTI-SILENT CIRCUIT BREAKER BLOCKED/);

    // 5th silent call evaluated before PLANNER_RESPONSE at step_index 9 is written -> denied
    const fifthUncoveredDenied = evaluateCircuitBreaker(
      [...historyThrough4, { type: 'GENERIC', step_index: 8, status: 'DONE' }],
      9
    );
    assert.equal(fifthUncoveredDenied.allowed, false);
    assert.equal(fifthUncoveredDenied.count, 5);
  });

  it('excludes denied GENERIC step (status: "ERROR") from future silent streak', () => {
    const history = [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Step 1',
        tool_calls: [{ id: 't1' }]
      },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 3,
        content: '',
        tool_calls: [{ id: 't2' }]
      },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 5,
        content: '',
        tool_calls: [{ id: 't3' }]
      },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: 't4-denied' }]
      },
      { type: 'GENERIC', step_index: 8, status: 'ERROR' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 9,
        content: '',
        tool_calls: [{ id: 't5-retry' }]
      }
    ];

    // Effective tools = 1 + 1 + 1 + 0 (errored step 8 excluded) + 1 = 4 -> allowed
    const result = evaluateCircuitBreaker(history, 10);
    assert.equal(result.allowed, true);
    assert.equal(result.count, 4);
  });

  it('resets prior silent streak on a visible text turn (string or parts array) but not whitespace', () => {
    const priorSilentStreak = [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Start',
        tool_calls: [{ id: 't1' }]
      },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 3,
        content: '',
        tool_calls: [{ id: 't2' }]
      },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 5,
        content: '',
        tool_calls: [{ id: 't3' }]
      },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: 't4' }]
      },
      { type: 'GENERIC', step_index: 8, status: 'DONE' }
    ];

    // String content resets streak
    const withTextReset = evaluateCircuitBreaker(
      [
        ...priorSilentStreak,
        {
          type: 'PLANNER_RESPONSE',
          source: 'MODEL',
          step_index: 9,
          content: 'Interim progress update to user.',
          tool_calls: [{ id: 't5' }]
        }
      ],
      10
    );
    assert.equal(withTextReset.allowed, true);
    assert.equal(withTextReset.count, 1);

    // Structured array content resets streak
    const withPartsReset = evaluateCircuitBreaker(
      [
        ...priorSilentStreak,
        {
          type: 'PLANNER_RESPONSE',
          source: 'MODEL',
          step_index: 9,
          content: [{ text: 'Structured interim status.' }],
          tool_calls: [{ id: 't5' }]
        }
      ],
      10
    );
    assert.equal(withPartsReset.allowed, true);
    assert.equal(withPartsReset.count, 1);

    // Whitespace-only content does NOT reset streak
    const withWhitespaceOnly = evaluateCircuitBreaker(
      [
        ...priorSilentStreak,
        {
          type: 'PLANNER_RESPONSE',
          source: 'MODEL',
          step_index: 9,
          content: '   \n\t  ',
          tool_calls: [{ id: 't5' }]
        }
      ],
      10
    );
    assert.equal(withWhitespaceOnly.allowed, false);
    assert.equal(withWhitespaceOnly.count, 5);
  });

  it('resets prior silent streak on USER_INPUT', () => {
    const history = [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Step 1',
        tool_calls: [{ id: 't1' }, { id: 't2' }, { id: 't3' }, { id: 't4' }]
      },
      { type: 'USER_INPUT', step_index: 6, content: 'Continue with phase 2' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: 't5' }]
      }
    ];

    const result = evaluateCircuitBreaker(history, 8);
    assert.equal(result.allowed, true);
    assert.equal(result.count, 1);
  });

  it('fails open on missing or empty history and skips corrupt JSONL lines', () => {
    assert.deepEqual(evaluateCircuitBreaker([], 1), { allowed: true, count: 1 });
    assert.deepEqual(evaluateCircuitBreaker(null, 1), { allowed: true, count: 1 });

    const dir = createTempDir();
    assert.deepEqual(readLastTranscriptLines(path.join(dir, 'does-not-exist.jsonl')), []);

    const corruptPath = writeJsonlTranscript(dir, 'corrupt.jsonl', [
      '{"truncated": ',
      'not json at all',
      { type: 'USER_INPUT', step_index: 1, content: 'ok' }
    ]);
    const parsed = readLastTranscriptLines(corruptPath);
    assert.equal(parsed.length, 1);
    assert.equal(parsed[0].type, 'USER_INPUT');
  });
});

describe('circuit-breaker CLI & symlink invocation', () => {
  it('fails open when transcriptPath is missing, non-existent, corrupt, or stdin is invalid JSON', () => {
    const dir = createTempDir();
    const corruptFile = writeJsonlTranscript(dir, 'only-corrupt.jsonl', [
      '{bad json',
      '<<<not-json>>>',
      '\u0000\u0001'
    ]);

    assert.deepEqual(runHookCli(HOOK_PATH, {}), { decision: 'allow' });
    assert.deepEqual(
      runHookCli(HOOK_PATH, { transcriptPath: path.join(dir, 'missing.jsonl'), stepIdx: 10 }),
      { decision: 'allow' }
    );
    assert.deepEqual(
      runHookCli(HOOK_PATH, { transcriptPath: corruptFile, stepIdx: 10 }),
      { decision: 'allow' }
    );
    assert.deepEqual(runHookCli(HOOK_PATH, '{invalid-stdin-json'), { decision: 'allow' });
    assert.deepEqual(runHookCli(HOOK_PATH, ''), { decision: 'allow' });
  });

  it('allows 4 parallel calls with visible text and denies 5th consecutive silent call via CLI', () => {
    const dir = createTempDir();

    const parallelAllowedTranscript = writeJsonlTranscript(dir, 'parallel.jsonl', [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Reading 4 files.',
        tool_calls: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }]
      }
    ]);

    for (const stepIdx of [2, 3, 4, 5]) {
      assert.deepEqual(
        runHookCli(HOOK_PATH, { transcriptPath: parallelAllowedTranscript, stepIdx }),
        { decision: 'allow' }
      );
    }

    const silent4Transcript = writeJsonlTranscript(dir, 'silent4.jsonl', [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Initial response.',
        tool_calls: [{ id: '1' }]
      },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 3,
        content: '',
        tool_calls: [{ id: '2' }]
      },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 5,
        content: '',
        tool_calls: [{ id: '3' }]
      },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: '4' }]
      }
    ]);

    const fourthResp = runHookCli(HOOK_PATH, { transcriptPath: silent4Transcript, stepIdx: 8 });
    assert.deepEqual(fourthResp, { decision: 'allow' });

    const silent5Transcript = writeJsonlTranscript(dir, 'silent5.jsonl', [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Initial response.',
        tool_calls: [{ id: '1' }]
      },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 3,
        content: '',
        tool_calls: [{ id: '2' }]
      },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 5,
        content: '',
        tool_calls: [{ id: '3' }]
      },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 7,
        content: '',
        tool_calls: [{ id: '4' }]
      },
      { type: 'GENERIC', step_index: 8, status: 'DONE' },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 9,
        content: '',
        tool_calls: [{ id: '5' }]
      }
    ]);

    const fifthResp = runHookCli(HOOK_PATH, { transcriptPath: silent5Transcript, step_index: 10 });
    assert.equal(fifthResp.decision, 'deny');
    assert.match(fifthResp.reason, /ANTI-SILENT CIRCUIT BREAKER BLOCKED/);
  });

  it('excludes ERROR GENERIC steps and resets streaks on visible text or USER_INPUT via CLI', () => {
    const dir = createTempDir();

    const errorExcludedTranscript = writeJsonlTranscript(dir, 'error-excluded.jsonl', [
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 1, content: 'S1', tool_calls: [{ id: '1' }] },
      { type: 'GENERIC', step_index: 2, status: 'DONE' },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 3, content: '', tool_calls: [{ id: '2' }] },
      { type: 'GENERIC', step_index: 4, status: 'DONE' },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 5, content: '', tool_calls: [{ id: '3' }] },
      { type: 'GENERIC', step_index: 6, status: 'DONE' },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 7, content: '', tool_calls: [{ id: '4' }] },
      { type: 'GENERIC', step_index: 8, status: 'ERROR' },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 9, content: '', tool_calls: [{ id: '5' }] }
    ]);
    assert.deepEqual(
      runHookCli(HOOK_PATH, { transcriptPath: errorExcludedTranscript, stepIdx: 10 }),
      { decision: 'allow' }
    );

    const textResetTranscript = writeJsonlTranscript(dir, 'text-reset.jsonl', [
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 1, content: 'S1', tool_calls: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }] },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 6, content: 'Progress update', tool_calls: [{ id: '5' }] }
    ]);
    assert.deepEqual(
      runHookCli(HOOK_PATH, { transcriptPath: textResetTranscript, stepIdx: 7 }),
      { decision: 'allow' }
    );

    const userResetTranscript = writeJsonlTranscript(dir, 'user-reset.jsonl', [
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 1, content: 'S1', tool_calls: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }] },
      { type: 'USER_INPUT', step_index: 6, content: 'Continue' },
      { type: 'PLANNER_RESPONSE', source: 'MODEL', step_index: 7, content: '', tool_calls: [{ id: '5' }] }
    ]);
    assert.deepEqual(
      runHookCli(HOOK_PATH, { transcriptPath: userResetTranscript, stepIdx: 8 }),
      { decision: 'allow' }
    );
  });

  it('works identically when invoked through a temp symlink (realpathSync check)', () => {
    const dir = createTempDir();
    const symlinkPath = path.join(dir, 'circuit-breaker-symlink.mjs');
    fs.symlinkSync(HOOK_PATH, symlinkPath);

    const allowTranscript = writeJsonlTranscript(dir, 'allow-link.jsonl', [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Visible update',
        tool_calls: [{ id: '1' }]
      }
    ]);

    const denyTranscript = writeJsonlTranscript(dir, 'deny-link.jsonl', [
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 1,
        content: 'Start',
        tool_calls: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }]
      },
      {
        type: 'PLANNER_RESPONSE',
        source: 'MODEL',
        step_index: 6,
        content: '',
        tool_calls: [{ id: '5' }]
      }
    ]);

    const allowRes = runHookCli(symlinkPath, { transcriptPath: allowTranscript, stepIdx: 2 });
    assert.deepEqual(allowRes, { decision: 'allow' });

    const denyRes = runHookCli(symlinkPath, { transcriptPath: denyTranscript, stepIdx: 7 });
    assert.equal(denyRes.decision, 'deny');
    assert.match(denyRes.reason, /ANTI-SILENT CIRCUIT BREAKER BLOCKED/);
  });
});
