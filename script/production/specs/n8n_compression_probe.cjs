// Test-only preload. Counts native compressor allocations in the unmodified image.
// Never mount this instrumentation in staging or production.
const fs = require('node:fs');
const zlib = require('node:zlib');
let count = 0;
fs.writeFileSync('/tmp/volitex-compressor-count', '0');
const countAllocation = name => {
  const original = zlib[name];
  Object.defineProperty(zlib, name, {
    ...Object.getOwnPropertyDescriptor(zlib, name),
    value: (...args) => {
      count += 1;
      fs.writeFileSync('/tmp/volitex-compressor-count', String(count));
      return original(...args);
    },
  });
};

countAllocation('createGzip');
countAllocation('createDeflate');
countAllocation('createBrotliCompress');
