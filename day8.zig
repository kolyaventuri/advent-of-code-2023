const std = @import("std");
const String = @import("utils/string.zig");

pub fn parseInstructions(lines: [][]const u8) !std.AutoHashMap([3]u8, [2][3]u8) {
    const allocator = std.heap.page_allocator;
    var instructions = std.AutoHashMap([3]u8, [2][3]u8).init(allocator);

    var t: u23 = 0;

    for (lines, 0..) |line, i| {
        _ = i;
        if (line.len == 0) {
            continue;
        }

        var coords: [2][3]u8 = undefined;
        var part: usize = 0;
        var index: usize = 0;
        var key: [3]u8 = undefined;
        var value: [3]u8 = undefined;

        for (line) |c| {
            if (c >= 65 and c <= 90) {
                // A - Z
                value[index] = c;
                index += 1;

                // std.debug.print("{s}", .{[1]u8{c}});
                continue;
            }

            // std.debug.print(" -> {d}\n", .{value});

            index = 0;
            part += 1;

            // const result: u23 = value[0] * 26 + value[1] * 26 + value[2];
            if (part == 4) {
                std.debug.print("{s}\n", .{&value});
                key = value;
                value = undefined;
            } else if (part > 5) {
                coords[part - 6] = value;
                std.debug.print("\twriting {s} to coords[{d}]\n", .{ value, part - 6 });
                value = undefined;
            }
        }

        std.debug.print("{s} -> {s} / {s}\n", .{ key, coords[0], coords[1] });

        try instructions.put(key, coords);
        t += 1;
    }

    std.debug.print("Added {d} total items\n", .{t});
    return instructions;
}

pub fn main() !void {
    const file = @embedFile("inputs/day8.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const moves = lines.items[0];
    const instructions = try parseInstructions(lines.items[2..]);
    var current = [3]u8{ 65, 65, 65 };
    var iterations: u32 = 0;
    var index: usize = 0;

    while (!std.mem.eql(u8, &current, "ZZZ")) {
        std.debug.print("Current = {s}\n", .{&current});
        const coords = instructions.get(current).?;
        std.debug.print("At {d}, coords = {d}, {d}, go {s}\n", .{ current, coords[0], coords[1], [1]u8{moves[index]} });

        const move = if (moves[index] == 76) coords[0] else coords[1];
        std.debug.print("{d} -> {d}\n", .{ current, move });
        current = move;
        iterations += 1;
        index += 1;
        if (index == moves.len) {
            index = 0;
        }
        std.debug.print("{d}\n", .{iterations});
    }

    std.debug.print("Moves = {d}\n", .{iterations});
}
