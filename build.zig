const std = @import("std");

const fs = std.fs;

pub fn build(b: *std.Build) !void {
    var allocator = std.heap.c_allocator;

    const dir = try fs.cwd().openIterableDir(".", .{});
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.startsWith(u8, entry.path, "day")) {
            const name = entry.basename[0 .. entry.basename.len - 4];
            const exe = b.addExecutable(.{
                .name = name,
                .root_source_file = .{ .path = entry.path },
            });

            b.installArtifact(exe);
        }
    }
}
