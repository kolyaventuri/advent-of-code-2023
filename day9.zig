const std = @import("std");
const String = @import("utils/string.zig");
const Reader = @import("utils/reader.zig");

pub fn main() !void {
    const file = @embedFile("inputs/day9.test.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    std.debug.print("Reader.readNumbers...\n", .{});
    const numberLine = try Reader.readNumbers(lines.items);
    defer numberLine.deinit();

    for (numberLine.items) |line| {
        std.debug.print("line: {d}\n", .{line.items});
    }
}
