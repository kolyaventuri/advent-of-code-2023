const std = @import("std");
const Loader = @import("utils/loader.zig");
const String = @import("utils/string.zig");

pub fn main() !void {
    const targetCubes = [3]i8{ 12, 13, 14 };
    const lines = try Loader.loadFile("inputs/day2.txt");

    var allocator = std.heap.page_allocator;
    var games = std.ArrayList(i16).init(allocator);
    var powers = std.ArrayList(i16).init(allocator);

    for (lines.items, 0..) |line, gameNumber| {
        if (line.len == 0) {
            continue;
        }
        const parts = try String.split(allocator, line, ":");
        const right = parts.items[1];
        //std.debug.print("Game {d}:\n", .{gameNumber + 1});

        const rounds = try String.split(allocator, right, ";");

        var maxCubes = [3]i16{ 0, 0, 0 };
        for (rounds.items, 0..) |round, r| {
            _ = r;
            //std.debug.print("  Round: {d}\n", .{r});
            const draws = try String.split(allocator, round, " ");

            var index: i4 = -1;
            var numbers = [2]i16{ -1, -1 };
            for (draws.items) |draw| {
                if (draw.len == 0) {
                    continue;
                }
                var i: usize = 0;
                index = -1;
                while (i < draw.len) {
                    const char = [1]u8{draw[i]};
                    //std.debug.print("      Char: {s} from '{s}'\n", .{ char, draw });
                    const number = std.fmt.parseInt(i16, &char, 10) catch -1;
                    if (number == -1) {
                        //std.debug.print("      Char: {s} from '{s}'\n", .{ char, draw });
                        if (std.mem.eql(u8, &char, "r")) {
                            index = 0;
                        } else if (std.mem.eql(u8, &char, "g")) {
                            index = 1;
                        } else if (std.mem.eql(u8, &char, "b")) {
                            index = 2;
                        }

                        break;
                    } else {
                        numbers[i] = number;
                    }

                    i += 1;
                }

                //std.debug.print("      BUILDSUM: Numbers: {d}, {d} from {d}, index: {d}\n", .{ numbers[0], numbers[1], numbers, index });
                var sum: i16 = 0;
                if (numbers[1] > -1) {
                    sum = (numbers[0] * 10) + numbers[1];
                } else {
                    sum = numbers[0];
                }
                if (index > -1) {
                    const index_usize = @as(usize, @intCast(index));
                    if (sum > maxCubes[index_usize]) {
                        //std.debug.print("    ADDMAX: Sum: {d}, curIndex: {d}, max: {d}\n", .{ sum, index, maxCubes[index_usize] });
                        maxCubes[index_usize] = sum;
                    }
                    numbers = [2]i16{ -1, -1 };
                }
                //std.debug.print("      Sum: {d} from: {d} + {d}, curIndex: {d}\n", .{ sum, numbers[0] * 10, numbers[1], index });
            }
        }

        //std.debug.print("    Max: {d}, {d}, {d}\n", .{ maxCubes[0], maxCubes[1], maxCubes[2] });
        try powers.append(maxCubes[0] * maxCubes[1] * maxCubes[2]);

        if (maxCubes[0] <= targetCubes[0]) {
            if (maxCubes[1] <= targetCubes[1]) {
                if (maxCubes[2] <= targetCubes[2]) {
                    //std.debug.print("    Adding game {d}\n", .{gameNumber + 1});
                    const gameNumber_int: i16 = @as(i16, @intCast(gameNumber));
                    try games.append(gameNumber_int + 1);
                }
            }
        }
    }

    var sum: i16 = 0;
    for (games.items) |game| {
        sum += game;
    }

    var totalPower: i32 = 0;
    for (powers.items) |power| {
        totalPower += power;
    }
    std.debug.print("Part1: {d}\n", .{sum});
    std.debug.print("Part2: {d}\n", .{totalPower});
}
