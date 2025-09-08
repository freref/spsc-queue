const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const unmanaged_any_spsc_mod = b.addModule("unmanaged_spsc_queue", .{
        .root_source_file = b.path("src/SpscQueueAnyUnmanaged.zig"),
        .target = target,
    });

    const unmanaged_po2_spsc_mod = b.addModule("unmanaged_any_spsc_queue", .{
        .root_source_file = b.path("src/SpscQueuePo2Unmanaged.zig"),
        .target = target,
    });

    const unmanaged_spsc_mod = b.addModule("unmanaged_spsc_queue", .{
        .root_source_file = b.path("src/SpscQueueUnmanaged.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "unmanaged_any_spsc_queue", .module = unmanaged_any_spsc_mod },
            .{ .name = "unmanaged_po2_spsc_queue", .module = unmanaged_po2_spsc_mod },
        },
    });

    const managed_spsc_mod = b.addModule("managed_spsc_queue", .{
        .root_source_file = b.path("src/SpscQueue.zig"),
        .target = target,
        .imports = &.{.{ .name = "unmanaged_spsc_queue", .module = unmanaged_spsc_mod }},
    });

    const root_mod = b.addModule("spsc_queue", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "unmanaged_spsc_queue", .module = unmanaged_spsc_mod },
            .{ .name = "managed_spsc_queue", .module = managed_spsc_mod },
        },
    });

    const example_exe = b.addExecutable(.{
        .name = "spsc_queue_example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "spsc_queue", .module = root_mod },
            },
        }),
    });
    b.installArtifact(example_exe);

    const run_example = b.step("run-example", "Run the example");
    const run_example_cmd = b.addRunArtifact(example_exe);
    run_example.dependOn(&run_example_cmd.step);
    if (b.args) |args| run_example_cmd.addArgs(args);

    const bench_exe = b.addExecutable(.{
        .name = "spsc_queue_benchmark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/benchmark.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "spsc_queue", .module = root_mod },
            },
        }),
    });
    b.installArtifact(bench_exe);

    const run_bench = b.step("run-benchmark", "Run the benchmark");
    const run_bench_cmd = b.addRunArtifact(bench_exe);
    run_bench.dependOn(&run_bench_cmd.step);
    if (b.args) |args| run_bench_cmd.addArgs(args);
}
