const std = @import("std");
const String = @import("utils/string.zig");

const Symbol = struct {
    is_gear: bool,
    x: i16,
    y: i16,
};

pub fn main() !void {
    const file = @embedFile("inputs/day3.txt");
    var stringAllocator = std.heap.page_allocator;
    const lines = try String.split(stringAllocator, file, "\n");

    defer lines.deinit();

    var allocator = std.heap.page_allocator;
    var numbers = std.ArrayList([4]i16).init(allocator);
    defer numbers.deinit();

    var symbols = std.ArrayList(Symbol).init(allocator);
    defer symbols.deinit();

    for (lines.items, 0..) |line, y| {
        var sum: i16 = 0;
        var place: i4 = 0;

        for (line, 0..) |char, x| {
            const c = [1]u8{char};

            // Ignore periods
            const number = std.fmt.parseInt(i16, &c, 10) catch -1;
            const isPeriod = std.mem.eql(u8, &c, ".");
            const isSymbol = number == -1 and !isPeriod;

            const x_int = @as(i16, @intCast(x));
            const y_int = @as(i16, @intCast(y));
            if (isPeriod or isSymbol) {
                if (isSymbol) {
                    //std.debug.print("IN: Adding {s} to symbols at [row: {d}, col: {d}]\n", .{ &c, y, x_int });
                    const data = Symbol{
                        .is_gear = std.mem.eql(u8, &c, "*"),
                        .x = x_int,
                        .y = y_int,
                    };
                    try symbols.append(data);
                }
                if (sum > 0) {
                    //std.debug.print("IN: Adding {d} to numbers at [row: {d}, col: {d} - {d}]\n", .{ sum, y, x_int - place, x_int - 1 });
                    const data = [4]i16{ sum, y_int, x_int - place, x_int - 1 };
                    try numbers.append(data);
                }
                place = 0;
                sum = 0;
                continue;
            }

            // It's a number
            place += 1;
            if (sum > 0) {
                sum *= 10;
            }
            sum += number;
            continue;
        }

        if (sum > 0) {
            const x_int: i16 = @as(i16, @intCast(line.len)) - 1;
            const y_int: i16 = @as(i16, @intCast(y));
            //std.debug.print("Adding {d} to numbers at [row: {d} , col: {d} - {d}]\n", .{ sum, y, x_int - place + 1, x_int });
            const data = [4]i16{ sum, y_int, x_int - place + 1, x_int };
            try numbers.append(data);
        }
    }

    // std.debug.print("Numbers: {d}\n", .{numbers.items});
    // for (symbols.items) |symbol| {
    //     std.debug.print("Symbol: gear? = {} @ [row: {d}, col: {d}]\n", .{ symbol.is_gear, symbol.y, symbol.x });
    // }

    var resultAccumulator = std.heap.page_allocator;
    var result = std.ArrayList([4]i16).init(resultAccumulator);
    defer result.deinit();

    var gearRatios = std.ArrayList(i32).init(resultAccumulator);
    defer gearRatios.deinit();

    for (symbols.items) |symbol| {
        var neighbors = [8][2]i16{
            [2]i16{ symbol.x - 1, symbol.y - 1 },
            [2]i16{ symbol.x - 1, symbol.y },
            [2]i16{ symbol.x - 1, symbol.y + 1 },
            [2]i16{ symbol.x, symbol.y - 1 },
            [2]i16{ symbol.x, symbol.y + 1 },
            [2]i16{ symbol.x + 1, symbol.y - 1 },
            [2]i16{ symbol.x + 1, symbol.y },
            [2]i16{ symbol.x + 1, symbol.y + 1 },
        };

        //std.debug.print("Looking at [row: {d}, col: {d}], isGear?: {}\n", .{ symbol.y, symbol.x, symbol.is_gear });
        //std.debug.print("Neighbors: {d}\n", .{neighbors});

        var adjacent = std.ArrayList([4]i16).init(resultAccumulator);
        defer adjacent.deinit();

        for (neighbors) |neighbor| {
            const x = neighbor[0];
            const y = neighbor[1];

            // Reject invalid neighbors
            if (y < 0 or x < 0) {
                continue;
            }

            for (numbers.items) |number| {
                var found = false;
                for (result.items) |res| {
                    if (res[1] == number[1] and res[2] == number[2]) {
                        found = true;
                        break;
                    }
                }
                if (found) {
                    // Short circuit if we already know this number is valid
                    continue;
                }
                const number_y = number[1];
                const number_x = number[2];
                const number_x_end = number[3];

                //std.debug.print("\tCompare {d} at [row: {d}, col: {d} - {d}] to point [row: {d}, col: {d}]\n", .{ number[0], number_y, number_x, number_x_end, y, x });
                if (number_y != y) {
                    //std.debug.print("\t\tNot same row {d} vs {d}\n", .{ number_y, y });
                    // Invalid neighbor
                    continue;
                }

                if (number_x != x and number_x_end != x) {
                    //std.debug.print("\t\tNot same col {d} vs {d} and {d} vs {d}\n", .{ number_x, x, number_x_end, x });
                    // Invalid neighbor
                    continue;
                }

                //std.debug.print("\t\tFound {d} at [row: {d}, col: {d} - {d}] to point [row: {d}, col: {d}]\n", .{ number[0], number_y, number_x, number_x_end, y, x });
                try result.append(number);
                try adjacent.append(number);
            }
        }
        if (adjacent.items.len == 2) {
            //std.debug.print("ADJACENCY: Found two numbers adjacent to a gear symbol: {d}\n", .{adjacent.items});
            const gearRatio = @as(i32, @intCast(adjacent.items[0][0])) * @as(i32, @intCast(adjacent.items[1][0]));
            try gearRatios.append(gearRatio);
        }
    }

    //std.debug.print("Numbers: {d}\n", .{result.items});
    var sum: i32 = 0;
    for (result.items) |res| {
        sum += res[0];
    }
    std.debug.print("Part 1: {d}\n", .{sum});

    var sum2: i32 = 0;
    for (gearRatios.items) |ratio| {
        sum2 += ratio;
    }
    std.debug.print("Part 2: {d}\n", .{sum2});
}
