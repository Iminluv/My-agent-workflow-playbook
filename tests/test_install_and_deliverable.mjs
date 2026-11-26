import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const SCRIPT_PATH = path.join(__dirname, 'test_install_and_deliverable.sh');

describe('install.sh, verify.sh, and verify-deliverable.sh integration', () => {
  it('passes all isolated install, verification, and deliverable checks', () => {
    const output = execFileSync('bash', [SCRIPT_PATH], {
      encoding: 'utf8',
      timeout: 110_000
    });
    assert.match(output, /Summary: \d+ passed, 0 failed/);
  });
});
