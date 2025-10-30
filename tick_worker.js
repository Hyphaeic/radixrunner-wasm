// tick_worker.js — glue-less worker that instantiates raw Wasm with our SAB memory.
console.log('[Tick Worker] Worker started');

self.onmessage = async (e) => {
  if (!e?.data || e.data.cmd !== 'init') return;

  try {
    const memory = e.data.memory;              // WebAssembly.Memory({ shared:true, ... })
    const wasmBytes = e.data.wasmBytes;        // ArrayBuffer from main.js fetch
    console.log('[Tick Worker] SAB?', memory.buffer instanceof SharedArrayBuffer, 'bytes=', memory.buffer.byteLength);

    // Compile and instantiate with our memory as an import
    const module = await WebAssembly.compile(wasmBytes);
    const imports = { env: { memory } };       // THE shared memory
    const instance = await WebAssembly.instantiate(module, imports);

    // Optional sanity
    const expMem = instance.exports.memory;
    if (expMem) {
      console.log('[Tick Worker] exports.memory is SAB?', expMem.buffer instanceof SharedArrayBuffer);
      console.log('[Tick Worker] same SAB?', expMem.buffer === memory.buffer);
    }

    // Initialize and start ticking (never returns)
    instance.exports.init_memory_base();
    self.postMessage({ type: 'ready' });
    instance.exports.tick_worker_main();

    console.warn('[Tick Worker] tick_worker_main returned unexpectedly');
  } catch (err) {
    console.error('[Tick Worker] Error:', err);
    self.postMessage({ type: 'error', error: String(err), stack: err?.stack });
  }
};
