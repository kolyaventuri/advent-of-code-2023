const std = @import("std");
const String = @import("utils/string.zig");

const pipes = std.ComptimeStringMap([]const u8, .{ .{ "|", "│" }, .{ "-", "─" }, .{ "L", "└" }, .{ "J", "┘" }, .{ "7", "┐" }, .{ "F", "┌" }, .{ ".", " " }, .{ "S", "@" } });

pub fn charToPipe(char: u8) []const u8 {
    return pipes.get(&[1]u8{char}).?;
}

pub fn printTile(char: u8) void {
    if (char == 83) {
        std.debug.print("\x1B[1m\x1B[32m", .{});
    }
    std.debug.print("{s}", .{charToPipe(char)});
    std.debug.print("\x1B[0m", .{});
}

pub fn main() !void {
    const file = @embedFile("inputs/day10.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    for (lines.items) |line| {
        for (line) |c| {
            printTile(c);
        }
        std.debug.print("\n", .{});
    }
}
