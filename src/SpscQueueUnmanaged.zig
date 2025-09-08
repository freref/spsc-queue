const std = @import("std");
const SpscQueueAnyUnmanaged = @import("SpscQueueAnyUnmanaged.zig").SpscQueueAnyUnmanaged;
const SpscQueuePo2Unmanaged = @import("SpscQueuePo2Unmanaged.zig").SpscQueuePo2Unmanaged;

// A single-producer, single-consumer lock-free queue using a ring buffer.
// Following the conventions from the Zig standard library.
pub fn SpscQueueUnmanaged(comptime T: type, comptime enforce_po2: bool) type {
    return if (comptime enforce_po2) SpscQueuePo2Unmanaged(T) else SpscQueueAnyUnmanaged(T);
}
