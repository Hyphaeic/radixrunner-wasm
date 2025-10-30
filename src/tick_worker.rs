use crate::memory_worm::MemoryWorm;

/// Tight producer loop: atomically increments the head.
pub fn run_tick_producer() {
    loop {
        MemoryWorm::tick();
        // If you want a tiny backoff: core::hint::spin_loop();
    }
}
