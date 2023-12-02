const std = @import("std");
const String = @import("./string.zig");

fn readFile(allocator: std.mem.Allocator, fileName: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

pub fn loadFile(fileName: []const u8) !std.ArrayList([]const u8) {
    const allocator = std.heap.page_allocator;
    const fileContents = try readFile(allocator, fileName);
    return try String.split(allocator, fileContents, "\n");
}
