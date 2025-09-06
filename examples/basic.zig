const std = @import("std");
const spsc_queue = @import("spsc_queue");

pub fn main() !void {
    var queue = try spsc_queue.SpscQueue(u32).initCapacity(std.heap.page_allocator, 1024);
    defer queue.deinit();

    _ = queue.tryPush(1234);
    _ = queue.front();
    queue.pop();
}
