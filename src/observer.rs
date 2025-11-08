// observer.rs 

use crate::memory_worm::{MemoryWorm, ShadowConfig, MAX_SHADOWS};
use core::sync::atomic::Ordering;

/// Observer main loop - detects overflows and updates shadow counters
/// Reads configs dynamically from SAB for runtime reconfiguration
pub fn run_observer() {
    // Last sampled digit values (for overflow detection)
    let mut last_digits = [0u32; 6];

    loop {
        // Read current main clock value
        let current = MemoryWorm::full();

        // Decode all digits
        let digits = [
            MemoryWorm::p0(),
            MemoryWorm::p1(),
            MemoryWorm::p2(),
            MemoryWorm::p3(),
            MemoryWorm::p4(),
            MemoryWorm::p5(),
        ];

        // Check each digit for overflow
        for digit_index in 0..6 {
            let current_value = digits[digit_index];
            let last_value = last_digits[digit_index];

            // Overflow detected: current < last (wrapped around)
            if current_value < last_value {
                // Handle overflow for this digit
                handle_overflow(digit_index as u8);
            }

            // Update last value
            last_digits[digit_index] = current_value;
        }

        // Hint to CPU this is a spin loop
        core::hint::spin_loop();
    }
}

/// Handle overflow on a specific digit
/// Reads shadow configs dynamically each time to support runtime reconfiguration
#[inline]
fn handle_overflow(digit: u8) {
    unsafe {
        let config_ptr = MemoryWorm::shadow_configs();
        
        // Check all shadows to see which ones are watching this digit
        for shadow_id in 0..MAX_SHADOWS {
            let config = &mut *config_ptr.add(shadow_id);

            // Skip if shadow is disabled or watching a different digit
            if config.enabled == 0 || config.source_digit != digit {
                continue;
            }

            // Increment overflow counter
            config.overflow_count += 1;

            // Check if we've hit the divisor threshold
            if config.overflow_count >= config.divisor {
                // Reset counter
                config.overflow_count = 0;

                // Increment shadow counter atomically
                MemoryWorm::shadow_counter(shadow_id).fetch_add(1, Ordering::Relaxed);
            }
        }
    }
}