const { test } = require('node:test');
const assert = require('node:assert/strict');
const { ssrRenderAttrs } = require('vue/server-renderer');

test('SSR rejects carriage returns in untrusted attribute names', () => {
  const rendered = ssrRenderAttrs(
    { src: 'x', 'x\ronerror': 'alert(1)' },
    'img'
  );
  assert.equal(rendered, ' src="x"');
});

test('SSR still escapes normal attribute values', () => {
  assert.equal(
    ssrRenderAttrs({ title: '<safe>"' }),
    ' title="&lt;safe&gt;&quot;"'
  );
});
