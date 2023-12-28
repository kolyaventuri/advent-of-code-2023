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
                // std.debug.print("{s}\n", .{&value});
                key = value;
                value = undefined;
            } else if (part > 5) {
                coords[part - 6] = value;
                // std.debug.print("\twriting {s} to coords[{d}]\n", .{ value, part - 6 });
                value = undefined;
            }
        }

        // std.debug.print("{s} -> {s} / {s}\n", .{ key, coords[0], coords[1] });

        try instructions.put(key, coords);
        t += 1;
    }

    // std.debug.print("Added {d} total items\n", .{t});
    return instructions;
}

fn followInstruction(
    current: [3]u8,
    index: u32,
    moves: []const u8,
    instructions: std.AutoHashMap([3]u8, [2][3]u8),
) u32 {
    std.debug.print("current node: {s}\n", .{&current});
    // Default case
    if (current[2] == 90) {
        return 1;
    }

    const instruction = instructions.get(current).?;
    const next = if (moves[index] == 76) instruction[0] else instruction[1];

    const nextIndex = if (index == moves.len - 1) 0 else index + 1;
    return 1 + followInstruction(next, nextIndex, moves, instructions);
}

fn gcd(a: u64, b: u64) u64 {
    if (b == 0) {
        return a;
    }

    return gcd(b, a % b);
}

fn lcm(numbers: std.ArrayList(u32)) u128 {
    var _lcm: u64 = numbers.items[0];
    for (numbers.items[1..]) |n| {
        var n1 = _lcm;
        var n2 = n;
        var gcd_val = gcd(n1, n2);
        _lcm = (_lcm * n) / gcd_val;
    }

    return _lcm;
}

pub fn main() !void {
    const file = @embedFile("inputs/day8.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const moves = lines.items[0];
    const instructions = try parseInstructions(lines.items[2..]);

    // Part 1

    var current = [3]u8{ 65, 65, 65 };
    var iterations: u32 = 0;
    var index: usize = 0;

    while (!std.mem.eql(u8, &current, "ZZZ")) {
        // std.debug.print("Current = {s}\n", .{&current});
        const coords = instructions.get(current).?;
        // std.debug.print("At {d}, coords = {d}, {d}, go {s}\n", .{ current, coords[0], coords[1], [1]u8{moves[index]} });

        const move = if (moves[index] == 76) coords[0] else coords[1];
        // std.debug.print("{d} -> {d}\n", .{ current, move });
        current = move;
        iterations += 1;
        index += 1;
        if (index == moves.len) {
            index = 0;
        }
        // std.debug.print("{d}\n", .{iterations});
    }

    std.debug.print("Part 1, Moves = {d}\n", .{iterations});

    // Part 2
    var p2_total_moves: u32 = 0;
    var p2_current = std.ArrayList([3]u8).init(allocator);
    defer p2_current.deinit();

    var p2_period = std.ArrayList(u32).init(allocator);
    defer p2_period.deinit();

    for (lines.items[2..]) |line| {
        if (line.len == 0) {
            continue;
        }
        const coordsA = line[0..3];
        if (coordsA[2] == 65) {
            const coords = [3]u8{ coordsA[0], coordsA[1], coordsA[2] };
            try p2_current.append(coords);
            try p2_period.append(0);
        }
    }

    index = 0;

    while (true) {
        var count_end: u8 = 0;
        for (p2_period.items) |p| {
            if (p > 0) {
                count_end += 1;
            }
        }

        // All current nodes are at the end
        if (count_end == p2_current.items.len) {
            break;
        }

        for (p2_current.items, 0..) |coord, i| {
            if (p2_period.items[i] != 0) {
                continue;
            }
            const coords = instructions.get(coord).?;
            const next = if (moves[index] == 76) coords[0] else coords[1];

            p2_current.items[i] = next;

            if (next[2] == 90) {
                p2_period.items[i] = p2_total_moves + 1;
            }
        }

        p2_total_moves += 1;
        index = if (index == moves.len - 1) 0 else index + 1;
    }

    const p2_lcm = lcm(p2_period);
    std.debug.print("Part 2, Moves = {d}\n", .{p2_lcm});
}
