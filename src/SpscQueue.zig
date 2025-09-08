const std = @import("std");
const SpscQueueUnmanaged = @import("SpscQueueUnmanaged.zig").SpscQueueUnmanaged;

// A single-producer, single-consumer lock-free queue using a ring buffer.
// Following the conventions from the Zig standard library.
pub fn SpscQueue(comptime T: type, comptime enforce_po2: bool) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        inner: SpscQueueUnmanaged(T, enforce_po2),

        /// Initialize with capacity to hold `num` elements.
        pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self {
            return Self{
                .allocator = allocator,
                .inner = try SpscQueueUnmanaged(T, enforce_po2).initCapacity(allocator, num),
            };
        }

        pub fn fromOwnedSlice(allocator: std.mem.Allocator, buffer: []T) Self {
            return Self{
                .allocator = allocator,
                .inner = SpscQueueUnmanaged(T, enforce_po2).initBuffer(buffer),
            };
        }

        pub fn deinit(self: *Self) void {
            self.inner.deinit(self.allocator);
        }

        // Returns true if the queue is empty.
        pub fn isEmpty(self: *Self) bool {
            return self.inner.isEmpty();
        }

        pub fn size(self: *Self) usize {
            return self.inner.size();
        }

        // Blocking push, spins until there is room in the queue.
        pub fn push(self: *Self, value: T) void {
            return self.inner.push(value);
        }

        // Non-blocking push, returns false if the queue is full.
        pub fn tryPush(self: *Self, value: T) bool {
            return self.inner.tryPush(value);
        }

        // Returns a pointer to the front item, or null if the queue is empty.
        pub fn front(self: *Self) ?*T {
            return self.inner.front();
        }

        // IMPORTANT: pop must only be called after front() returned non-null.
        // The consumer is responsible for cleaning up the item if needed.
        pub fn pop(self: *Self) void {
            return self.inner.pop();
        }
    };
}
