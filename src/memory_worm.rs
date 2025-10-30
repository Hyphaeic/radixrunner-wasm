use core::sync::atomic::{AtomicU64, Ordering};

// Memory layout constants
pub const WORM_HEAD_OFFSET: usize   = 0x0000;
pub const RADIX_HEAD_OFFSET: usize  = 0x0100; // 8 bytes (AtomicU64)
pub const APP_SECTIONS_OFFSET: usize = 0x1000;

// Bit layout [P5:12][P4:10][P3:10][P2:10][P1:10][P0:12]
pub const P0_BITS: u32 = 12; pub const P0_MASK: u64 = 0xFFF; pub const P0_SHIFT: u32 = 0;
pub const P1_BITS: u32 = 10; pub const P1_MASK: u64 = 0x3FF; pub const P1_SHIFT: u32 = 12;
pub const P2_BITS: u32 = 10; pub const P2_MASK: u64 = 0x3FF; pub const P2_SHIFT: u32 = 22;
pub const P3_BITS: u32 = 10; pub const P3_MASK: u64 = 0x3FF; pub const P3_SHIFT: u32 = 32;
pub const P4_BITS: u32 = 10; pub const P4_MASK: u64 = 0x3FF; pub const P4_SHIFT: u32 = 42;
pub const P5_BITS: u32 = 12; pub const P5_MASK: u64 = 0xFFF; pub const P5_SHIFT: u32 = 52;

// Raw base pointer into linear memory
static mut WORM_BASE: *mut u8 = core::ptr::null_mut();

pub struct MemoryWorm;

impl MemoryWorm {
    #[inline]
    pub unsafe fn init(base: *mut u8) {
        WORM_BASE = base;
        // Touch the head location (no-op; helps ensure addr is valid)
        let ptr = WORM_BASE.add(RADIX_HEAD_OFFSET) as *mut AtomicU64;
        let _ = (*ptr).load(Ordering::Relaxed);
    }

    #[inline]
    pub fn radix_head() -> &'static AtomicU64 {
        unsafe {
            let ptr = WORM_BASE.add(RADIX_HEAD_OFFSET) as *mut AtomicU64;
            &*ptr
        }
    }

    /// Single tick increment on the 64-bit head (wraps mod 2^64).
    #[inline]
    pub fn tick() {
        Self::radix_head().fetch_add(1, Ordering::Relaxed);
    }

    #[inline] pub fn full() -> u64 { Self::radix_head().load(Ordering::Relaxed) }

    // Optional: per-bin reads (one-shot; not used by the tight loop)
    #[inline] pub fn p0() -> u32 { ((Self::full() >> P0_SHIFT) & P0_MASK) as u32 }
    #[inline] pub fn p1() -> u32 { ((Self::full() >> P1_SHIFT) & P1_MASK) as u32 }
    #[inline] pub fn p2() -> u32 { ((Self::full() >> P2_SHIFT) & P2_MASK) as u32 }
    #[inline] pub fn p3() -> u32 { ((Self::full() >> P3_SHIFT) & P3_MASK) as u32 }
    #[inline] pub fn p4() -> u32 { ((Self::full() >> P4_SHIFT) & P4_MASK) as u32 }
    #[inline] pub fn p5() -> u32 { ((Self::full() >> P5_SHIFT) & P5_MASK) as u32 }

    #[inline]
    pub fn section_start(id: u32) -> *mut u8 {
        unsafe { WORM_BASE.add(APP_SECTIONS_OFFSET + (id as usize * 0x1000)) }
    }
}
