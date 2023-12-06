const std = @import("std");
const String = @import("utils/string.zig");

const Data = struct { destination: i64, range_start: i64, range_size: i64 };

pub fn main() !void {
    const file = @embedFile("inputs/day6.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var times = [4]i16{ 0, 0, 0, 0 };
    var distances = [4]i16{ 0, 0, 0, 0 };

    for (lines.items, 0..) |line, i| {
        var values = if (i == 0) &times else &distances;
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
            }

            if (num == -1 or j == line.len - 1) {
                values[index] = temp;
                index += 1;
                temp = -1;
            }
        }

        std.debug.print("\n", .{});
    }

    // std.debug.print("Times: {d}\n", .{times});
    // std.debug.print("Distances: {d}\n", .{distances});

    var total: i32 = 1;
    for (times, 0..) |time, i| {
        if (time == 0) {
            continue;
        }
        const winning_distance = distances[i];

        const time_float = @as(f16, @floatFromInt(time));
        const distance_float = @as(f16, @floatFromInt(winning_distance));

        const rt = @sqrt((time_float * time_float) - (4 * distance_float));
        const t_x = -time_float + rt;
        const t_x2 = -time_float - rt;

        const x1_t = @divExact(t_x, 2);
        const x1_f = @floor(x1_t);
        const x1 = if (x1_t > x1_f) x1_f + 1 else x1_f;
        const x2 = @divFloor(t_x2, 2);

        const ways = @as(i32, @intFromFloat(x1 - x2 - 1));

        total *= ways;
    }

    std.debug.print("Part 1: {d}\n", .{total});
}
