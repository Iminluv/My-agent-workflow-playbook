import { describe, it, after } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { extractCommand, evaluateCommand } from '../hooks/validate-tool-call.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');
const HOOK_PATH = path.join(REPO_ROOT, 'hooks', 'validate-tool-call.mjs');

const tempDirs = [];

function createTempDir(prefix = 'ag-vtc-test-') {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  tempDirs.push(dir);
  return dir;
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

describe('validate-tool-call unit evaluation', () => {
  it('blocks destructive Unix, mkfs, dd, and Windows root/format commands', () => {
    const destructiveCases = [
      { cmd: 'rm -rf /', rule: 'unix-root-delete' },
      { cmd: 'rm -rf /*', rule: 'unix-root-delete' },
      { cmd: 'sudo rm -fr /', rule: 'unix-root-delete' },
      { cmd: 'echo ok && rm -rf /', rule: 'unix-root-delete' },
      { cmd: 'mkfs.ext4 /dev/disk2', rule: 'filesystem-format' },
      { cmd: 'sudo mkfs -t ext4 /dev/sdb1', rule: 'filesystem-format' },
      { cmd: 'dd if=/dev/zero of=/dev/nvme0n1', rule: 'raw-disk-overwrite' },
      { cmd: 'dd if=/dev/urandom of=/dev/sda bs=1M', rule: 'raw-disk-overwrite' },
      { cmd: 'format C:', rule: 'windows-drive-format' },
      { cmd: 'Remove-Item -Recurse -Force C:\\', rule: 'windows-root-delete' }
    ];

    for (const { cmd, rule } of destructiveCases) {
      const result = evaluateCommand(cmd);
      assert.equal(result.allowed, false, `expected '${cmd}' to be blocked`);
      assert.equal(result.rule, rule);
    }
  });

  it('allows safe development commands', () => {
    const safeCommands = [
      'rm -rf ./tmp',
      'rm -rf /tmp/ag-kit-build',
      'git status',
      'make test',
      'node --test tests/*.mjs'
    ];

    for (const cmd of safeCommands) {
      const result = evaluateCommand(cmd);
      assert.equal(result.allowed, true, `expected '${cmd}' to be allowed`);
      assert.equal(result.rule, null);
    }
  });

  it('extracts commands from supported Antigravity payload schemas', () => {
    assert.equal(extractCommand({ toolCall: { args: { CommandLine: 'git status' } } }), 'git status');
    assert.equal(extractCommand({ tool_args: { commandLine: 'make test' } }), 'make test');
    assert.equal(extractCommand({ toolArgs: { command: 'rm -rf ./tmp' } }), 'rm -rf ./tmp');
    assert.equal(extractCommand({ arguments: { cmd: 'ls -la' } }), 'ls -la');
    assert.equal(extractCommand({ command: 'pwd' }), 'pwd');
    assert.equal(extractCommand({ cmd: 'echo ok' }), 'echo ok');
    assert.equal(extractCommand({}), '');
  });
});

describe('validate-tool-call CLI & symlink invocation', () => {
  it('denies destructive commands and allows safe commands via direct CLI', () => {
    const blockedCommands = [
      'rm -rf /',
      'mkfs.ext4 /dev/disk2',
      'dd if=/dev/zero of=/dev/nvme0n1'
    ];

    for (const cmd of blockedCommands) {
      const res = runHookCli(HOOK_PATH, { toolCall: { args: { CommandLine: cmd } } });
      assert.equal(res.decision, 'deny', `expected CLI to deny '${cmd}'`);
      assert.match(res.reason, /^BLOCKED by AG Kit \(/);
    }

    const safeCommands = ['rm -rf ./tmp', 'git status', 'make test'];
    for (const cmd of safeCommands) {
      const res = runHookCli(HOOK_PATH, { toolCall: { args: { CommandLine: cmd } } });
      assert.deepEqual(res, { decision: 'allow' });
    }
  });

  it('fails open on empty, missing command, or malformed JSON stdin', () => {
    assert.deepEqual(runHookCli(HOOK_PATH, {}), { decision: 'allow' });
    assert.deepEqual(runHookCli(HOOK_PATH, ''), { decision: 'allow' });
    assert.deepEqual(runHookCli(HOOK_PATH, '{not-valid-json'), { decision: 'allow' });
  });

  it('works identically when invoked through a temp symlink (realpathSync check)', () => {
    const dir = createTempDir();
    const symlinkPath = path.join(dir, 'validate-tool-call-symlink.mjs');
    fs.symlinkSync(HOOK_PATH, symlinkPath);

    const denyRes = runHookCli(symlinkPath, { toolCall: { args: { CommandLine: 'rm -rf /' } } });
    assert.equal(denyRes.decision, 'deny');
    assert.match(denyRes.reason, /unix-root-delete/);

    const allowRes = runHookCli(symlinkPath, { toolCall: { args: { CommandLine: 'git status' } } });
    assert.deepEqual(allowRes, { decision: 'allow' });
  });
});
