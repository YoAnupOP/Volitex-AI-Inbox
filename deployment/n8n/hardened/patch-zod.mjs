import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

// ABI-preserving port of the constrained-container early-exit fix from
// https://github.com/colinhacks/zod/pull/6652 to the bundled v3 and v4 runtimes.
// Unbounded schemas are intentionally unchanged, just as in upstream 4.6.6.
const pristine = {
  'v3/types.cjs':
    '06487cc05ed45c5dd29789bf0aa75734d1ce06592a7f2665ba4ca90a68e8a3e1',
  'v3/types.js':
    '9763a2938f0e7f983363ef4bf6530e7583e3f2d54f8a4a6684efad58febc6e8e',
  'v4/core/schemas.cjs':
    'f5d17a7db487c943c9d07cc624010ebb6d93683eabd14339846f4912cc88b51f',
  'v4/core/schemas.js':
    'd466582c022b08a3f9eb1a65d5970d8ca25064d73a5a838d76414ae36440a76b',
};
const sha256 = source => createHash('sha256').update(source).digest('hex');
function replaceOnce(source, before, after) {
  assert.equal(source.split(before).length, 2, `Changed Zod anchor: ${before}`);
  return source.replace(before, after);
}
const capSizeSource = `// Reject oversized containers before allocating per-element results or issues.
const volitexOversized = new WeakSet();
function volitexSizeCaps(checks) {
    const caps = [];
    for (const check of checks ?? []) {
        const def = check._zod.def;
        // Preserve check/transform ordering: only leading size checks may move.
        if (!/_(length|size)$|_equals$/.test(def.check)) break;
        const maximum = def.maximum ?? def.length ?? def.size;
        if (maximum >= 0) caps.push([maximum, check]);
    }
    return caps;
}
function volitexCapSize(inst, size) {
    const caps = volitexSizeCaps(inst._zod.def.checks);
    if (!caps.length) return;
    const maximum = Math.min(...caps.map(([limit]) => limit));
    const parse = inst._zod.parse;
    inst._zod.parse = (payload, ctx) => {
        const count = size(payload.value);
        if (count > maximum && !ctx?.skipChecks && ctx?.direction !== "backward") {
            for (const [limit, check] of volitexSizeCaps(inst._zod.def.checks)) {
                if (count > limit && check._zod.def.when(payload)) {
                    const start = payload.issues.length;
                    check._zod.check(payload);
                    payload.issues[start].continue = false;
                    volitexOversized.add(payload);
                    return payload;
                }
            }
        }
        return parse(payload, ctx);
    };
}
`;

export function patchZod(directory) {
  const files = {};
  for (const [relative, original] of Object.entries(pristine)) {
    const file = path.join(directory, relative);
    let source = fs.readFileSync(file, 'utf8');
    assert.equal(sha256(source), original, `Changed Zod source: ${relative}`);
    if (relative.startsWith('v3/')) {
      const invalid = relative.endsWith('.cjs')
        ? 'parseUtil_js_1.INVALID'
        : 'INVALID';
      const start = source.indexOf('class ZodArray extends ZodType');
      const end = source.indexOf('function deepPartialify', start);
      let array = source.slice(start, end);
      array = replaceOnce(
        array,
        '        if (ctx.common.async) {',
        '        if ((def.exactLength !== null && ctx.data.length > def.exactLength.value) ||\n' +
          '            (def.maxLength !== null && ctx.data.length > def.maxLength.value)) return ' +
          invalid +
          ';\n' +
          '        if (ctx.common.async) {'
      );
      source = source.slice(0, start) + array + source.slice(end);
      const setStart = source.indexOf('class ZodSet extends ZodType');
      const setEnd = source.indexOf(
        'class ZodFunction extends ZodType',
        setStart
      );
      let set = source.slice(setStart, setEnd);
      set = replaceOnce(
        set,
        '        const valueType = this._def.valueType;',
        '        if (def.maxSize !== null && ctx.data.size > def.maxSize.value) return ' +
          invalid +
          ';\n' +
          '        const valueType = this._def.valueType;'
      );
      source = source.slice(0, setStart) + set + source.slice(setEnd);
    } else {
      source = replaceOnce(
        source,
        'const runChecks = (payload, checks, ctx) => {',
        'const runChecks = (payload, checks, ctx) => {\n            if (volitexOversized.delete(payload)) return payload;'
      );
      source = replaceOnce(
        source,
        'function handleArrayResult(',
        capSizeSource + 'function handleArrayResult('
      );
      for (const [kind, size] of [
        ['Array', 'Array.isArray(input) ? input.length : -1'],
        ['Map', 'input instanceof Map ? input.size : -1'],
        ['Set', 'input instanceof Set ? input.size : -1'],
      ]) {
        const start = source.indexOf('core.$constructor("$Zod' + kind + '",');
        assert.ok(start >= 0);
        const end = source.indexOf('\n});', start);
        assert.ok(end > start);
        source =
          source.slice(0, end) +
          '\n    volitexCapSize(inst, (input) => ' +
          size +
          ');' +
          source.slice(end);
      }
    }
    fs.writeFileSync(file, source);
    files[relative] = {
      original_sha256: original,
      patched_sha256: sha256(source),
    };
  }
  return {
    name: 'zod',
    version: '3.25.76',
    advisory: 'CVE-2023-54404',
    directory,
    scope: 'constrained-container-early-exit-v3-v4-cjs-esm',
    files,
  };
}
