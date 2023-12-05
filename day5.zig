const std = @import("std");
const String = @import("utils/string.zig");

const Data = struct { destination: i64, range_start: i64, range_size: i64 };

fn cmpByData(_: void, a: Data, b: Data) bool {
    return a.destination < b.destination;
}

pub fn main() !void {
    const file = @embedFile("inputs/day5.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var index: usize = 0;
    var sections = [8]std.ArrayList(i64){ std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator), std.ArrayList(i64).init(allocator) };
    for (sections) |section| {
        defer section.deinit();
    }

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
            for (numbers.items) |n| {
                try sections[index].append(n);
            }
        }
    }

    var lists = [_]std.ArrayList(Data){std.ArrayList(Data).init(allocator)} ** 7;
    for (lists) |list| {
        defer list.deinit();
    }

    for (sections[1..sections.len], 0..) |section, i| {
        // std.debug.print("Section {d} (size {d})...\n", .{ i + 1, section.items.len });
        var j: usize = 0;
        while (j < section.items.len) {
            const destination = section.items[j];
            const range_start = section.items[j + 1];
            const range_size = section.items[j + 2];

            const data = Data{ .destination = destination, .range_start = range_start, .range_size = range_size };

            try lists[i].append(data);

            // std.debug.print("\tStored row {d} vs {d}\n", .{ j, section.items.len });

            j += 3;
        }

        std.mem.sort(Data, lists[i].items, {}, cmpByData);
    }
    // std.debug.print("Done parsing.\n", .{});
    // End Parse

    // Begin logic
    var min: i64 = -1;
    for (sections[0].items) |seed| {
        var temp: i64 = seed;
        // std.debug.print("Seed {d}: {d}\n", .{ seed, seed });
        for (lists) |list| {
            for (list.items) |data| {
                const destination_start = data.destination;
                const source_start = data.range_start;
                const size = data.range_size - 1;

                if (temp >= source_start and temp <= source_start + size) {
                    // std.debug.print("{d} -> ", .{temp});
                    // std.debug.print("(s: {d}, se: {d})", .{ source_start, source_start + size });
                    // std.debug.print("(d: {d}, de: {d})", .{ destination_start, destination_start + size });
                    const offset = destination_start - source_start;
                    temp = temp + offset;
                    break;
                }
            }
            // std.debug.print("\n", .{});
        }

        // std.debug.print("Check {d}\n", .{temp});
        if (min == -1) {
            min = temp;
        } else if (temp < min) {
            min = temp;
        }
    }

    std.debug.print("Part 1: {d}\n", .{min});
}
