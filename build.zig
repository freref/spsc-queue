const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spsc_mod = b.addModule("spsc_queue", .{
        .root_source_file = b.path("src/spsc_queue.zig"),
        .target = target,
    });

    const example_exe = b.addExecutable(.{
        .name = "spsc_queue_example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "spsc_queue", .module = spsc_mod },
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
                .{ .name = "spsc_queue", .module = spsc_mod },
            },
        }),
    });
    b.installArtifact(bench_exe);

    const run_bench = b.step("run-benchmark", "Run the benchmark");
    const run_bench_cmd = b.addRunArtifact(bench_exe);
    run_bench.dependOn(&run_bench_cmd.step);
    if (b.args) |args| run_bench_cmd.addArgs(args);
}
