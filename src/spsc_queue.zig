const std = @import("std");

// We align the producer and consumer to different cache lines to avoid false
// sharing between them. We pad the producer and consumer to ensure that they
// take up a full cache line each. We assume the cache line is bigger than
// atomic.Value(usize).
const Producer = struct {
    push_cursor: std.atomic.Value(usize) = .{ .raw = 0 },
    _pad: [std.atomic.cache_line - @sizeOf(std.atomic.Value(usize))]u8 = undefined,
};

const Consumer = struct {
    pop_cursor: std.atomic.Value(usize) = .{ .raw = 0 },
    _pad: [std.atomic.cache_line - @sizeOf(std.atomic.Value(usize))]u8 = undefined,
};

// A single-producer, single-consumer lock-free queue using a ring buffer.
// Following the conventions from the Zig standard library.
pub fn SpscQueue(comptime T: type) type {
    return struct {
        const Self = @This();
        const cache_line = std.atomic.cache_line;

        allocator: std.mem.Allocator,
        items: []T,
        producer: Producer align(cache_line) = .{},
        consumer: Consumer align(cache_line) = .{},

        pop_cursor_cache: usize = 0,
        push_cursor_cache: usize = 0,

        /// Initialize with capacity to hold `num` elements.
        /// Deinitialize with `deinit`.
        pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self {
            std.debug.assert(num >= 1);

            const n = num + 1;
            const items = try allocator.alignedAlloc(
                T,
                std.mem.Alignment.fromByteUnits(cache_line),
                n,
            );

            return Self{ .allocator = allocator, .items = items };
        }

        /// Initialize with externally-managed memory. The buffer determines the
        /// capacity. Calling `deinit` will result in illegsl behavior.
        pub fn initBuffer(buffer: []T) Self {
            std.debug.assert(buffer.len >= 2);
            return Self{ .items = buffer };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        // Returns true if the queue is empty.
        pub fn isEmpty(self: *Self) bool {
            const r = self.consumer.pop_cursor.load(.acquire);
            const w = self.producer.push_cursor.load(.acquire);
            return r == w;
        }

        pub fn size(self: *Self) usize {
            const r = self.consumer.pop_cursor.load(.acquire);
            const w = self.producer.push_cursor.load(.acquire);
            const n = self.items.len;
            return (w + n - r) % n;
        }

        // Blocking push, spins until there is room in the queue.
        pub fn push(self: *Self, value: T) void {
            const w = self.producer.push_cursor.load(.monotonic);
            var next = w + 1;
            if (next == self.items.len) next = 0;

            // Spin until there is room.
            while (next == self.pop_cursor_cache) {
                self.pop_cursor_cache = self.consumer.pop_cursor.load(.acquire);

                if (next == self.pop_cursor_cache) {
                    std.atomic.spinLoopHint();
                }
            }

            self.items[w] = value;
            self.producer.push_cursor.store(next, .release);
        }

        // Non-blocking push, returns false if the queue is full.
        pub fn tryPush(self: *Self, value: T) bool {
            const w = self.producer.push_cursor.load(.monotonic);
            var next = w + 1;
            if (next == self.items.len) next = 0;

            // Refresh cached read index if we *think* it's full.
            if (next == self.pop_cursor_cache) {
                self.pop_cursor_cache = self.consumer.pop_cursor.load(.acquire);
                // Cache is full if the next index catches up with the read index.
                if (next == self.pop_cursor_cache) return false;
            }

            self.items[w] = value;
            self.producer.push_cursor.store(next, .release);
            return true;
        }

        // Returns a pointer to the front item, or null if the queue is empty.
        pub fn front(self: *Self) ?*T {
            const r = self.consumer.pop_cursor.load(.monotonic);

            if (r == self.push_cursor_cache) {
                self.push_cursor_cache = self.producer.push_cursor.load(.acquire);
                if (self.push_cursor_cache == r) return null;
            }

            return &self.items[r];
        }

        // IMPORTANT: pop must only be called after front() returned non-null.
        // The consumer is responsible for cleaning up the item if needed.
        pub fn pop(self: *Self) void {
            const r = self.consumer.pop_cursor.load(.monotonic);

            std.debug.assert(self.producer.push_cursor.load(.acquire) != r);

            var next = r + 1;
            if (next == self.items.len) next = 0;

            self.consumer.pop_cursor.store(next, .release);
        }
    };
}
