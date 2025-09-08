const std = @import("std");
const spsc_queue = @import("spsc_queue");

pub fn main() !void {
    // Create a queue for u32 not enforcing power-of-two capacity
    var queue = try spsc_queue.SpscQueue(u32, false).initCapacity(std.heap.page_allocator, 1);
    defer queue.deinit();

    var t = try std.Thread.spawn(.{}, struct {
        fn run(q: *spsc_queue.SpscQueue(u32)) void {
            while (q.front() == null) {
                std.atomic.spinLoopHint();
            }
            const ptr = q.front().?;
            // Optinally: destroy item here
            std.debug.print("{}\n", .{ptr.*});
            q.pop();
        }
    }.run, .{&queue});

    queue.push(42);
    t.join();
}
