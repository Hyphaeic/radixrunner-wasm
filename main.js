// main.js — creates SAB-backed WebAssembly.Memory and verifies shared ticking.
console.log('[Main] Starting standalone WASM test...');

async function init() {
  const statusEl = document.getElementById('status');

  try {
    statusEl.textContent = 'Creating shared memory...';

    // 256 pages * 64KiB = 16 MiB (must match build link-args!)
    const memory = new WebAssembly.Memory({
      initial: 256,
      maximum: 256,
      shared: true,
    });

    console.log('[Main] Shared memory created');
    console.log('[Main] Buffer is SharedArrayBuffer:', memory.buffer instanceof SharedArrayBuffer);
    console.log('[Main] Buffer size:', memory.buffer.byteLength);

    // Zero the head for a clean start
    const view = new DataView(memory.buffer);
    const RADIX_HEAD_OFFSET = 0x100;
    view.setBigUint64(RADIX_HEAD_OFFSET, 0n, true);

    statusEl.textContent = 'Loading WASM bytes for worker...';

    // Fetch the raw wasm (built by scripts/build.sh)
    const wasmPath = './pkg/radixrunner_bg.wasm';
    const resp = await fetch(wasmPath);
    if (!resp.ok) throw new Error(`Failed to fetch ${wasmPath}: ${resp.status} ${resp.statusText}`);
    const wasmBytes = await resp.arrayBuffer();

    console.log('[Main] WASM bytes loaded:', wasmBytes.byteLength);

    statusEl.textContent = 'Spawning tick worker...';

    // ES module worker (file is sibling at project root)
    const tickWorker = new Worker('./tick_worker.js', { type: 'module' });

    tickWorker.onerror = (err) => {
      console.error('[Main] Tick worker error:', err);
      statusEl.textContent = 'ERROR: Tick worker failed';
      statusEl.classList.add('error');
    };

    tickWorker.onmessage = (e) => {
      if (e.data?.type === 'error') {
        console.error('[Main] Tick worker error:', e.data.error);
        statusEl.textContent = 'ERROR: ' + e.data.error;
        statusEl.classList.add('error');
      } else if (e.data?.type === 'ready') {
        console.log('[Main] Tick worker ready');

        // Check after a short delay to see increments
        setTimeout(() => {
          const low  = view.getUint32(RADIX_HEAD_OFFSET, true);
          const high = view.getUint32(RADIX_HEAD_OFFSET + 4, true);
          const full = (BigInt(high) << 32n) | BigInt(low);
          console.log('[Main] Memory check after 100ms: 0x' + full.toString(16));

          if (full > 0n) {
            console.log('[Main] ✅ Memory is being updated!');
            statusEl.textContent = '✅ WASM Runtime Active - Clock Running';
            statusEl.classList.remove('error');
            statusEl.classList.add('success');
            startMonitoring(memory);
          } else {
            console.error('[Main] ❌ Memory still at 0 - not shared properly');
            statusEl.textContent = '❌ ERROR: Memory not shared';
            statusEl.classList.add('error');
          }
        }, 100);
      }
    };

    // Kick off worker init
    tickWorker.postMessage({ cmd: 'init', memory, wasmBytes });
  } catch (err) {
    console.error('[Main] Initialization failed:', err);
    statusEl.textContent = '❌ ERROR: ' + String(err);
    statusEl.classList.add('error');
  }
}

function startMonitoring(memory) {
  const RADIX_HEAD_OFFSET = 0x100;
  console.log('[Main] Starting monitor, memory buffer size:', memory.buffer.byteLength);

  let last = 0n;
  let lastTime = performance.now();

  function update() {
    try {
      const view = new DataView(memory.buffer);
      const full = view.getBigUint64(RADIX_HEAD_OFFSET, true);

      // Rough tick rate once a second
      const now = performance.now();
      const dt = now - lastTime;
      if (dt > 1000) {
        const d = full - last;
        const tps = Number(d) / (dt / 1000);
        console.log('[Main] Tick rate:', tps.toFixed(0), 'ticks/s');
        last = full;
        lastTime = now;
      }

      // Decode bins (12/10/10/10/10/12)
      const p0 = Number(full & 0xFFFn);
      const p1 = Number((full >> 12n) & 0x3FFn);
      const p2 = Number((full >> 22n) & 0x3FFn);
      const p3 = Number((full >> 32n) & 0x3FFn);
      const p4 = Number((full >> 42n) & 0x3FFn);
      const p5 = Number((full >> 52n) & 0xFFFn);

      document.getElementById('p0').textContent = p0;
      document.getElementById('p1').textContent = p1;
      document.getElementById('p2').textContent = p2;
      document.getElementById('p3').textContent = p3;
      document.getElementById('p4').textContent = p4;
      document.getElementById('p5').textContent = p5;
      document.getElementById('full').textContent = '0x' + full.toString(16).padStart(16, '0');

      requestAnimationFrame(update);
    } catch (err) {
      console.error('[Main] Monitor error:', err);
      requestAnimationFrame(update);
    }
  }

  update();
}

// Boot
init();
