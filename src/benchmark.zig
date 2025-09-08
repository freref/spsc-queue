const std = @import("std");
const spsc_queue = @import("spsc_queue");

const total_rounds: u64 = 10_000_000;
const capacity: usize = 16_777_216;

fn spscReadWorker(q: *spsc_queue.SpscQueue(i32, true), rounds: u64) void {
    var i: u64 = 0;
    while (i < rounds) {
        while (q.front() == null) {}
        const val = q.front().?.*;
        if (val != i) @panic("out of order");
        q.pop();
        i += 1;
    }
}

pub fn main() !void {
    var queue = try spsc_queue.SpscQueue(i32, true).initCapacity(std.heap.page_allocator, capacity);
    defer queue.deinit();

    var reader = try std.Thread.spawn(.{}, spscReadWorker, .{ &queue, total_rounds });

    const start_ns: i128 = std.time.nanoTimestamp();

    var i: i32 = 0;
    while (i < total_rounds) : (i += 1) {
        queue.push(i);
    }

    reader.join();

    const end_ns: i128 = std.time.nanoTimestamp();
    const elapsed_ns: u128 = @intCast(end_ns - start_ns);
    const ops_per_ms: u128 = (@as(u128, total_rounds) * 1_000_000) / elapsed_ns;

    std.debug.print("{d} ops/ms\n", .{ops_per_ms});
}
