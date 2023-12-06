const std = @import("std");
const String = @import("utils/string.zig");

pub fn getNumWaysToWin(race_time: i64, winning_distance: i64) i64 {
    const time_float = @as(f64, @floatFromInt(race_time));
    const distance_float = @as(f64, @floatFromInt(winning_distance));

    const rt = @sqrt((time_float * time_float) - (4 * distance_float));
    const t_x = -time_float + rt;
    const t_x2 = -time_float - rt;

    const x1_t = @divExact(t_x, 2);
    const x1_f = @floor(x1_t);
    const x1 = if (x1_t > x1_f) x1_f + 1 else x1_f;
    const x2 = @divFloor(t_x2, 2);

    const ways = @as(i64, @intFromFloat(x1 - x2 - 1));

    return ways;
}

pub fn main() !void {
    const file = @embedFile("inputs/day6.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var times = [4]i16{ 0, 0, 0, 0 };
    var distances = [4]i16{ 0, 0, 0, 0 };

    var part2_time: i64 = 0;
    var part2_distance: i64 = 0;

    for (lines.items, 0..) |line, i| {
        var values = if (i == 0) &times else &distances;
        var p2_value = if (i == 0) &part2_time else &part2_distance;
        var temp: i16 = -1;
        var index: usize = 0;
        for (line, 0..) |c, j| {
            const char = [1]u8{c};
            const num = std.fmt.parseInt(i8, &char, 10) catch -1;
            if (num == -1 and temp == -1) {
                continue;
            }
            if (num > -1) {
                if (temp < 0) {
                    temp = 0;
                }
                temp *= 10;
                temp += num;

                p2_value.* *= 10;
                p2_value.* += num;
            }

            if (num == -1 or j == line.len - 1) {
                values[index] = temp;
                index += 1;
                temp = -1;
            }
        }
    }

    // std.debug.print("Times: {d}\n", .{times});
    // std.debug.print("Distances: {d}\n", .{distances});
    // std.debug.print("P2 Time: {d}\n", .{part2_time});
    // std.debug.print("P2 Distance: {d}\n", .{part2_distance});

    var total: i64 = 1;
    for (times, 0..) |time, i| {
        if (time == 0) {
            continue;
        }

        total *= getNumWaysToWin(time, distances[i]);
    }

    std.debug.print("Part 1: {d}\n", .{total});

    const part2 = getNumWaysToWin(part2_time, part2_distance);
    std.debug.print("Part 2: {d}\n", .{part2});
}
