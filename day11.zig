const std = @import("std");
const String = @import("utils/string.zig");

fn parseGrid(allocator: *std.mem.Allocator, lines: *std.ArrayList([]const u8)) !std.ArrayList(std.ArrayList(u1)) {
    var grid = std.ArrayList(std.ArrayList(u1)).init(allocator.*);

    for (lines.items) |line| {
        if (line.len == 0) {
            continue;
        }
        var row = std.ArrayList(u1).init(allocator.*);
        var row_empty = true;
        for (line) |char| {
            switch (char) {
                '.' => try row.append(0),
                '#' => {
                    row_empty = false;
                    try row.append(1);
                },
                else => unreachable,
            }
        }
        try grid.append(row);
        // Every empty row (no galaxies) "expands"
        if (row_empty) {
            try grid.append(row);
        }
    }

    // Iterate over the columns and append extra empty columns
    var extra = std.ArrayList(usize).init(allocator.*);
    defer extra.deinit();

    var i: usize = 0;
    while (i < grid.items[0].items.len) {
        var is_empty_col = true;
        for (grid.items) |row| {
            if (row.items[i] == 1) {
                is_empty_col = false;
                break;
            }
        }

        if (is_empty_col) {
            try extra.append(i);
        }

        i += 1;
    }

    i = 0;
    for (extra.items) |col| {
        const n = col + i;
        for (grid.items, 0..) |_, j| {
            try grid.items[j].insert(n, 0);
        }
        i += 1;
    }

    return grid;
}

fn printGrid(grid: *std.ArrayList(std.ArrayList(u1))) void {
    for (grid.items) |row| {
        for (row.items) |item| {
            if (item == 1) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn getGalaxies(allocator: *std.mem.Allocator, grid: *std.ArrayList(std.ArrayList(u1))) !std.ArrayList([2]usize) {
    var galaxies = std.ArrayList([2]usize).init(allocator.*);

    for (grid.items, 0..) |row, i| {
        for (row.items, 0..) |item, j| {
            if (item == 1) {
                try galaxies.append([2]usize{ i, j });
            }
        }
    }

    return galaxies;
}

fn shortestPath(start: [2]usize, end: [2]usize) !i16 {
    const x1 = @as(i16, @intCast(start[0]));
    const x2 = @as(i16, @intCast(end[0]));
    const y1 = @as(i16, @intCast(start[1]));
    const y2 = @as(i16, @intCast(end[1]));

    return try std.math.absInt(x1 - x2) + try std.math.absInt(y1 - y2);
}

pub fn main() !void {
    const file = @embedFile("inputs/day11.txt");
    var allocator = std.heap.c_allocator;
    var lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var grid = try parseGrid(&allocator, &lines);
    defer grid.deinit();
    // printGrid(&grid);

    var galaxies = try getGalaxies(&allocator, &grid);
    defer galaxies.deinit();
    var total_paths: i32 = 0;
    for (galaxies.items, 0..) |galaxyA, i| {
        for (galaxies.items[i + 1 ..]) |galaxyB| {
            total_paths += try shortestPath(galaxyA, galaxyB);
        }
    }
    std.debug.print("\n", .{});

    std.debug.print("Part 1 = {d}\n", .{total_paths});
}
