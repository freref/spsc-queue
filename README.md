# spsc_queue.zig
A single producer single consumer wait-free and lock-free fixed size queue written in Zig. Inspired by [rigtorp's](https://github.com/rigtorp/SPSCQueue/tree/master) implementation in C++. This implementation is faster than [SPSCQueue by rigtorp](https://github.com/rigtorp/SPSCQueue/tree/master),
[*boost::lockfree::spsc*](https://www.boost.org/doc/libs/1_76_0/doc/html/boost/lockfree/spsc_queue.html), and [*folly::ProducerConsumerQueue*](https://github.com/facebook/folly/blob/master/folly/docs/ProducerConsumerQueue.md)
