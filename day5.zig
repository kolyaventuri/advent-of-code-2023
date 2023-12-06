const std = @import("std");
const String = @import("utils/string.zig");

const Data = struct { destination: i64, range_start: i64, range_size: i64 };

fn cmpByData(_: void, a: Data, b: Data) bool {
    return a.destination < b.destination;
}

pub fn main() !void {
    const file = @embedFile("inputs/day5.test.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var index: usize = 0;
    var sections = [7]std.ArrayList(i64){ std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator) };
    for (sections) |section| {
        defer section.deinit();
    }

    var seed_list = std.ArrayList([2]i64).init(allocator);
    defer seed_list.deinit();

    // Parsing
    for (lines.items) |line| {
        if (line.len == 0) {
            index += 1;
            continue;
        }

        var temp: i64 = -1;
        var numbers = std.ArrayList(i64).init(allocator);
        defer numbers.deinit();

        for (line, 0..) |c, i| {
            const char = [1]u8{c};
            const num = std.fmt.parseInt(i8, &char, 10) catch -1;
            const is_space = std.mem.eql(u8, &char, " ");
            if (num == -1 and !is_space) {
                temp = -1;

                // First line is formatted "label: 1 2 3"
                if (index == 0) {
                    continue;
                }
                break;
            } else if (num == -1) {
                if (temp > -1) {
                    try numbers.append(temp);
                }
                temp = -1;

                continue;
            }

            if (temp == -1) {
                temp = 0;
            }

            // std.debug.print("({d} -> {d} + {d}) ", .{ temp, temp * 10, num });
            temp *= 10;
            temp += num;

            if (i == line.len - 1) {
                try numbers.append(temp);
            }
        }

        if (numbers.items.len > 0) {
            if (index == 0) {
                var j: usize = 0;
                while (j < numbers.items.len) {
                    try seed_list.append([2]i64{ numbers.items[j], numbers.items[j + 1] });
                    j += 2;
                }
                continue;
            }
            for (numbers.items) |n| {
                try sections[index - 1].append(n);
            }
        }
    }

    var maps = [_]std.ArrayList(Data){std.ArrayList(Data).init(allocator)} ** 7;
    for (maps) |list| {
        defer list.deinit();
    }

    for (sections, 0..) |section, i| {
        // std.debug.print("Section {d} (size {d})...\n", .{ i + 1, section.items.len });
        var j: usize = 0;
        while (j < section.items.len) {
            const destination = section.items[j];
            const range_start = section.items[j + 1];
            const range_size = section.items[j + 2];

            const data = Data{ .destination = destination, .range_start = range_start, .range_size = range_size };

            try maps[i].append(data);

            // std.debug.print("\tStored row {d} vs {d}\n", .{ j, section.items.len });

            j += 3;
        }

        std.mem.sort(Data, maps[i].items, {}, cmpByData);
    }
    // std.debug.print("Done parsing.\n", .{});
    // End Parse

    // Begin logic
    var min: i64 = -1;
    for (seed_list.items) |seed| {
        var t_left = seed[0];
        var t_right = t_left + seed[1] - 1;
        std.debug.print("Seed {d} -> {d} (count: {d})\n", .{ t_left, t_right, seed[1] });
        for (maps, 0..) |map, m| {
            std.debug.print("Map({d}), start: t_left = {d}, t_right = {d}\n", .{ m + 1, t_left, t_right });

            for (map.items) |data| {
                const range_end = data.range_start + data.range_size - 1;
                std.debug.print("Range: {d} -> {d}\n", .{ data.range_start, range_end });
                std.debug.print("\tExpeted output range: {d} -> {d}\n", .{ data.destination, data.destination + data.range_size - 1 });
                const move = data.destination - data.range_start;
                std.debug.print("\tMove by {d}\n", .{move});
                if (t_left > range_end) {
                    continue;
                }

                if (t_right < data.range_start) {
                    continue;
                }

                // We're within the valid start range
                const offset_left = t_left - data.range_start;
                var min_left: i64 = 0;
                var max_right: i64 = 0;

                if (data.range_start > t_left) {
                    min_left = data.range_start;
                } else {
                    min_left = t_left;
                }

                if (range_end < t_right) {
                    max_right = range_end;
                } else {
                    max_right = t_right;
                }

                std.debug.print("\tofffset_left={d}, min_left={d}, max_right={d}\n", .{ offset_left, min_left, max_right });

                t_left = min_left + move;
                t_right = max_right + move;
                std.debug.print("\tNew t_left={d}\n", .{t_left});
                std.debug.print("\tNew t_right={d}\n", .{t_right});
            }

            std.debug.print("\n", .{});
        }

        std.debug.print("Final t_left = {d}, t_right={d}\n", .{ t_left, t_right });
        if (min == -1) {
            min = t_left;
        } else if (t_left < min) {
            min = t_left;
        }

        break;
    }

    std.debug.print("Part 1: {d}\n", .{min});
}
