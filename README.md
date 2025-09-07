# spsc_queue.zig
A single producer single consumer wait-free and lock-free fixed size queue written in Zig. Inspired by [rigtorp's](https://github.com/rigtorp/SPSCQueue/tree/master) implementation in C++. This implementation is faster than [rigtorp's SPSC queue](https://github.com/rigtorp/SPSCQueue/tree/master),
[*boost::lockfree::spsc*](https://www.boost.org/doc/libs/1_76_0/doc/html/boost/lockfree/spsc_queue.html), and [*folly::ProducerConsumerQueue*](https://github.com/facebook/folly/blob/master/folly/docs/ProducerConsumerQueue.md)

# Usage
This library provides a managed and an unmanaged version of the queue, following the Zig standard library conventions.
The managed version allocates memory for the queue using a provided allocator or takes ownership of a provided buffer.
The unmanaged version requires the user to provide a buffer, or a caller-owned allocator to allocate memory for the queue.

**Unmanaged version:**
```zig
pub fn initBuffer(buffer: []T) Self
pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self
pub fn deinit(self: *Self, allocator: std.mem.Allocator) void
```

**Managed version:**
```zig
pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self
pub fn fromOwnedSlice(allocator: std.mem.Allocator, buffer: []T) Self
pub fn deinit(self: *Self) void
```

**General API:**
```zig
pub fn isEmpty(self: *Self) bool
pub fn size(self: *Self) usize
pub fn push(self: *Self, value: T) void
pub fn tryPush(self: *Self, value: T) bool
pub fn front(self: *Self) ?*T
pub fn pop(self: *Self) void
```
