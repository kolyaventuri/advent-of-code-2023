const std = @import("std");
const String = @import("utils/string.zig");
const Reader = @import("utils/reader.zig");

pub fn generateTriangle(allocator: std.mem.Allocator, input: std.ArrayList(i64)) !std.ArrayList(std.ArrayList(i64)) {
    var new_list = std.ArrayList(std.ArrayList(i64)).init(allocator);
    var current_line = input;

    try new_list.append(input);

    while (true) {
        // std.debug.print("New row: ", .{});
        var new_row = std.ArrayList(i64).init(allocator);

        for (current_line.items, 0..) |item, index| {
            if (index < current_line.items.len - 1) {
                const diff = current_line.items[index + 1] - item;
                try new_row.append(diff);
                // std.debug.print(" {d}", .{diff});
            }
        }

        // std.debug.print("\n", .{});
        try new_list.append(new_row);

        // Are we done?
        var n_zeroes: u16 = 0;
        for (new_row.items) |item| {
            if (item == 0) {
                n_zeroes += 1;
            }
        }

        if (n_zeroes == new_row.items.len) {
            break;
        }

        current_line = new_row;
    }

    return new_list;
}

pub fn main() !void {
    const file = @embedFile("inputs/day9.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const numberLine = try Reader.readNumbers(lines.items);
    defer numberLine.deinit();

    var total_history: i64 = 0;
    var part2_history: i64 = 0;
    for (numberLine.items, 0..) |line, k| {
        _ = k;
        const triangle = try generateTriangle(allocator, line);
        defer triangle.deinit();

        var i: usize = triangle.items.len - 1;
        var right_history: i64 = 0;
        var left_history: i64 = 0;

        while (i > 0) {
            i -= 1;
            const curr = triangle.items[i].items;
            const next_value = curr[curr.len - 1] + right_history;
            right_history = next_value;

            const left_value = curr[0] - left_history;
            left_history = left_value;
        }

        // std.debug.print("Line {d}: Right {d}, Left: {d}\n", .{ k + 1, right_history, left_history });
        total_history += right_history;
        part2_history += left_history;
    }

    std.debug.print("Part 1: {d}\n", .{total_history});
    std.debug.print("Part 2: {d}\n", .{part2_history});
}
