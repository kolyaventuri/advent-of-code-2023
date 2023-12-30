const std = @import("std");
const String = @import("utils/string.zig");

fn parseGrid(allocator: *std.mem.Allocator, lines: *std.ArrayList([]const u8)) !std.ArrayList(std.ArrayList(u1)) {
    var grid = std.ArrayList(std.ArrayList(u1)).init(allocator.*);

    for (lines.items) |line| {
        if (line.len == 0) {
            continue;
        }
        var row = std.ArrayList(u1).init(allocator.*);
        for (line) |char| {
            switch (char) {
                '.' => try row.append(0),
                '#' => try row.append(1),
                else => unreachable,
            }
        }
        try grid.append(row);
        // Every empty row (no galaxies) "expands"
        // if (row_empty) {
        //     try grid.append(row);
        // }
    }

    // // Iterate over the columns and append extra empty columns
    // var extra = std.ArrayList(usize).init(allocator.*);
    // defer extra.deinit();

    // var i: usize = 0;
    // while (i < grid.items[0].items.len) {
    //     var is_empty_col = true;
    //     for (grid.items) |row| {
    //         if (row.items[i] == 1) {
    //             is_empty_col = false;
    //             break;
    //         }
    //     }

    //     if (is_empty_col) {
    //         try extra.append(i);
    //     }

    //     i += 1;
    // }

    // i = 0;
    // for (extra.items) |col| {
    //     const n = col + i;
    //     for (grid.items, 0..) |_, j| {
    //         try grid.items[j].insert(n, 0);
    //     }
    //     i += 1;
    // }

    return grid;
}

fn digits(num: usize) usize {
    if (num == 0) {
        return 1;
    }

    const w_float = std.math.floor(std.math.log10(@as(f16, @floatFromInt(@as(i16, @intCast(num))))) + 1);
    const width = @as(usize, @intFromFloat(w_float));

    return width;
}

fn printGrid(grid: *std.ArrayList(std.ArrayList(u1))) void {
    const width = digits(grid.items.len);
    var n: usize = 0;
    while (n < width + 1) {
        std.debug.print(" ", .{});
        n += 1;
    }

    for (grid.items[0].items, 0..) |_, i| {
        std.debug.print("{d} ", .{i});
    }
    std.debug.print("\n", .{});
    for (grid.items, 0..) |row, i| {
        std.debug.print("{d}", .{i});
        var k: usize = digits(i);
        while (k < width + 1) {
            std.debug.print(" ", .{});
            k += 1;
        }
        for (row.items) |item| {
            if (item == 1) {
                std.debug.print("# ", .{});
            } else {
                std.debug.print(". ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn isRowEmpty(row: *const std.ArrayList(u1)) bool {
    var empty = true;

    for (row.items) |item| {
        if (item == 1) {
            empty = false;
            break;
        }
    }

    return empty;
}

fn isColEmpty(grid: *const std.ArrayList(std.ArrayList(u1)), col: usize) bool {
    var empty = true;

    for (grid.items) |row| {
        if (row.items[col] == 1) {
            empty = false;
            break;
        }
    }

    return empty;
}

fn getGalaxies(allocator: *std.mem.Allocator, grid: *std.ArrayList(std.ArrayList(u1)), expansion: u32) !std.ArrayList([2]usize) {
    var galaxies = std.ArrayList([2]usize).init(allocator.*);

    var empty_cols: usize = 0;
    var empty_rows: usize = 0;

    for (grid.items, 0..) |row, y| {
        if (isRowEmpty(&row)) {
            empty_rows += 1;
            continue;
        }

        empty_cols = 0;
        for (row.items, 0..) |item, x| {
            if (isColEmpty(grid, x)) {
                empty_cols += 1;
                continue;
            }

            if (item == 1) {
                const offsetX = empty_cols * (expansion - 1);
                const offsetY = empty_rows * (expansion - 1);
                try galaxies.append([2]usize{ x + offsetX, y + offsetY });
            }
        }
    }

    return galaxies;
}

fn shortestPath(start: [2]usize, end: [2]usize) !i32 {
    const x1 = @as(i32, @intCast(start[0]));
    const x2 = @as(i32, @intCast(end[0]));
    const y1 = @as(i32, @intCast(start[1]));
    const y2 = @as(i32, @intCast(end[1]));

    return try std.math.absInt(x1 - x2) + try std.math.absInt(y1 - y2);
}

fn getSumOfShortestPaths(galaxies: *std.ArrayList([2]usize)) !i64 {
    var total_paths: i64 = 0;
    for (galaxies.items, 0..) |galaxyA, i| {
        for (galaxies.items[i + 1 ..]) |galaxyB| {
            total_paths += try shortestPath(galaxyA, galaxyB);
        }
    }

    return total_paths;
}

pub fn main() !void {
    const file = @embedFile("inputs/day11.txt");
    var allocator = std.heap.c_allocator;
    var lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var grid = try parseGrid(&allocator, &lines);
    defer grid.deinit();
    // printGrid(&grid);

    var galaxies_p1 = try getGalaxies(&allocator, &grid, 2);
    defer galaxies_p1.deinit();

    std.debug.print("\n", .{});

    const p1_total = try getSumOfShortestPaths(&galaxies_p1);
    std.debug.print("Part 1 = {d}\n", .{p1_total});

    var galaxies_p2 = try getGalaxies(&allocator, &grid, 1000000);
    defer galaxies_p2.deinit();

    std.debug.print("\n", .{});

    const p2_total = try getSumOfShortestPaths(&galaxies_p2);
    std.debug.print("Part 2 = {d}\n", .{p2_total});
}
