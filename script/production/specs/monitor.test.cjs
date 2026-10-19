const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

for (const scenario of [
  'healthy',
  'eviction',
  'disabled-aof',
  'write-error',
  'invalid',
  'unreachable',
  'alert-failure',
  'docker-error',
  'n8n-crashed',
  'n8n-inspection-error',
]) {
  test(`monitor: ${scenario}`, () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'volitex-monitor-'));
    try {
      const commands = {
        psql: `#!/bin/bash
if [[ "$*" == *execution_entity* ]]; then
  [[ "$SCENARIO" != n8n-inspection-error ]] || exit 1
  [[ "$SCENARIO" != n8n-crashed ]] || { echo 1; exit; }
  echo 0
elif [[ "$*" == *max_connections* ]]; then echo 100
else echo 0; fi
`,
        curl: '#!/bin/bash\n[[ "$*" != *operator.invalid* ]] || { echo alert >> "$TEST_ALERT"; [[ "$SCENARIO" != alert-failure ]]; }\n',
        jq: '#!/bin/bash\ncat >/dev/null; echo \'{"text":"test alert"}\'\n',
        awk: '#!/bin/bash\ncase "$1" in *MemAvailable*) echo 900;; *MemTotal*) echo 1000;; *) exec /usr/bin/awk "$@";; esac\n',
        docker: '#!/bin/bash\n[[ "$SCENARIO" != docker-error ]]\n',
        df: '#!/bin/bash\nprintf "Filesystem 1024-blocks Used Available Capacity Mounted\\ntest 100 1 99 1%% /\\n"\n',
        'redis-cli': `#!/bin/bash
if [[ "$*" == *llen* ]]; then echo 0; exit; fi
[[ "$*" == *'INFO memory stats persistence'* ]] || exit 9
case "$SCENARIO" in
  invalid|alert-failure) echo 'NOAUTH Authentication required.'; exit 0;;
  unreachable) exit 1;;
esac
echo "evicted_keys:$([[ "$SCENARIO" == eviction ]] && echo 1 || echo 0)"
echo "aof_enabled:$([[ "$SCENARIO" == disabled-aof ]] && echo 0 || echo 1)"
echo "aof_last_write_status:$([[ "$SCENARIO" == write-error ]] && echo err || echo ok)"
echo 'rdb_last_bgsave_status:ok'
`,
      };
      for (const [name, body] of Object.entries(commands)) {
        fs.writeFileSync(path.join(dir, name), body, { mode: 0o700 });
      }
      const result = spawnSync(
        process.env.BASH_EXECUTABLE || 'bash',
        [
          '-c',
          `
if command -v cygpath >/dev/null; then TEST_BIN=$(cygpath -u "$TEST_BIN"); MONITOR_PATH=$(cygpath -u "$MONITOR_PATH"); TEST_ALERT=$(cygpath -u "$TEST_ALERT"); export TEST_ALERT; fi
export PATH="$TEST_BIN:$PATH"
exec bash "$MONITOR_PATH"
`,
        ],
        {
          encoding: 'utf8',
          timeout: 10000,
          env: {
            ...process.env,
            TEST_BIN: dir,
            MONITOR_PATH: path.resolve('deployment/production/monitor.sh'),
            TEST_ALERT: path.join(dir, 'alert'),
            SCENARIO: scenario,
            INBOX_HEALTH_URL: 'https://inbox.invalid/health',
            N8N_HEALTH_URL: 'https://automation.invalid/healthz',
            ALERT_WEBHOOK_URL: 'https://operator.invalid/alert',
            VOLITEX_REDIS_URL: 'redis://test.invalid/0',
            N8N_REDIS_URL: 'redis://test.invalid/1',
            VOLITEX_DATABASE_URL: 'postgresql://test.invalid/inbox',
            N8N_DATABASE_URL: 'postgresql://test.invalid/n8n',
            MEMORY_USED_ALERT_PERCENT: '101',
          },
        }
      );
      assert.ifError(result.error);
      // Alert transport must also fail closed; never report a healthy monitor.
      const healthy = scenario === 'healthy';
      assert.equal(result.status, healthy ? 0 : 1, result.stderr);
      assert.equal(fs.existsSync(path.join(dir, 'alert')), !healthy);
    } finally {
      fs.rmSync(dir, { recursive: true });
    }
  });
}
