#![cfg_attr(target_arch = "wasm32", no_std)]

#[cfg(target_arch = "wasm32")]
use core::sync::atomic::{AtomicU64, Ordering};
#[cfg(not(target_arch = "wasm32"))]
use std::sync::atomic::{AtomicU64, Ordering};

#[cfg(target_arch = "wasm32")]
use core::panic::PanicInfo;

pub mod memory_worm;
pub mod tick_worker;
pub mod observer;

// Optional shared state (works on both targets)
static MEMORY_BASE: AtomicU64 = AtomicU64::new(0);

/// Panic handler only for wasm32-no_std. On host (rust-analyzer), we keep std,
/// so we must NOT define a panic handler (avoids duplicate `panic_impl`).
#[cfg(target_arch = "wasm32")]
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // Trap cleanly in wasm32
    unsafe { core::arch::wasm32::unreachable() }
}

/// Initialize memory base and wire the worm. Exported with C ABI for glue-less use.
#[no_mangle]
pub extern "C" fn init_memory_base() {
    MEMORY_BASE.store(0, Ordering::Relaxed);
    unsafe { memory_worm::MemoryWorm::init(0 as *mut u8); }
    let _ = memory_worm::MemoryWorm::full();
}

/// Infinite tick loop (runs in a dedicated Web Worker).
#[no_mangle]
pub extern "C" fn tick_worker_main() {
    tick_worker::run_tick_producer();
}

/// Observer worker main loop (never returns)
#[no_mangle]
pub extern "C" fn observer_worker_main() {
    observer::run_observer();
}

/// Debug helpers (optional)
#[no_mangle]
pub extern "C" fn debug_read_memory() -> u64 {
    memory_worm::MemoryWorm::full()
}

#[no_mangle]
pub extern "C" fn debug_write_memory(value: u64) {
    unsafe {
        let ptr = memory_worm::MemoryWorm::radix_head() as *const AtomicU64 as *mut AtomicU64;
        (*ptr).store(value, Ordering::Relaxed);
    }
}
