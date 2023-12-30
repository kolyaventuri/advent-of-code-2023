const std = @import("std");
const String = @import("utils/string.zig");
const Queue = @import("utils/queue.zig").Queue;

const Pipe = struct {
    char: []const u8,
    x1: i2,
    x2: i2,
    y1: i2,
    y2: i2,
};

const Square = struct { pipe: Pipe, x: usize, y: usize, visited: bool, parent: ?*Square };

const pipes = std.ComptimeStringMap(Pipe, .{ .{ "|", Pipe{ .char = "│", .x1 = 0, .x2 = 0, .y1 = -1, .y2 = 1 } }, .{ "-", Pipe{ .char = "─", .x1 = -1, .x2 = 1, .y1 = 0, .y2 = 0 } }, .{ "L", Pipe{ .char = "└", .x1 = 0, .x2 = 1, .y1 = -1, .y2 = 0 } }, .{ "J", Pipe{ .char = "┘", .x1 = -1, .x2 = 0, .y1 = -1, .y2 = 0 } }, .{ "7", Pipe{ .char = "┐", .x1 = -1, .x2 = 0, .y1 = 0, .y2 = 1 } }, .{ "F", Pipe{ .char = "┌", .x1 = 0, .x2 = 1, .y1 = 0, .y2 = 1 } }, .{ ".", Pipe{ .char = " ", .x1 = 0, .x2 = 0, .y1 = 0, .y2 = 0 } }, .{ "S", Pipe{ .char = "@", .x1 = -1, .x2 = 1, .y1 = -1, .y2 = 1 } } });

fn charToPipe(char: u8) Pipe {
    return pipes.get(&[1]u8{char}).?;
}

fn printTile(char: []const u8) void {
    // Make the starting point green
    if (char[0] == 64) {
        std.debug.print("\x1B[1m\x1B[32m", .{});
    }
    std.debug.print("{s}", .{char});
    std.debug.print("\x1B[0m", .{});
}

fn printGridPos(grid: std.ArrayList(std.ArrayList(Square)), x: ?usize, y: ?usize, reject_neighbors: bool) void {
    for (grid.items, 0..) |line, y1| {
        for (line.items, 0..) |square, x1| {
            if (x1 == x and y1 == y) {
                std.debug.print("\x1B[31m", .{});
                std.debug.print("*", .{});
                std.debug.print("\x1B[0m", .{});
            } else {
                if (reject_neighbors and !square.visited) {
                    std.debug.print(" ", .{});
                } else {
                    printTile(square.pipe.char);
                }
            }
        }

        std.debug.print("\n", .{});
    }
}

fn printGrid(grid: std.ArrayList(std.ArrayList(Square))) void {
    printGridPos(grid, null, null, false);
}

fn printGridRejectInvalidNeighbors(grid: std.ArrayList(std.ArrayList(Square))) void {
    printGridPos(grid, null, null, true);
}

fn isInList(list: *std.ArrayList(*Square), square: *Square) bool {
    for (list.items) |item| {
        if (item.x == square.x and item.y == square.y) {
            return true;
        }
    }

    return false;
}

fn printGridColorLines(grid: std.ArrayList(std.ArrayList(Square)), start: *Square) !void {
    var flat_list = std.ArrayList(*Square).init(std.heap.c_allocator);
    defer flat_list.deinit();

    var current: ?*Square = start;
    while (current != null) {
        if (current.?.visited) {
            try flat_list.append(current.?);
        }
        if (current.?.parent == start) {
            break;
        }
        current = current.?.parent;
    }

    for (grid.items) |line| {
        for (line.items) |square| {
            if (square.visited) {
                std.debug.print("\x1B[31m", .{});
                std.debug.print("{s}", .{square.pipe.char});
                std.debug.print("\x1B[0m", .{});
            } else {
                printTile(square.pipe.char);
            }
        }

        std.debug.print("\n", .{});
    }
}

fn isValidNeighbor(pipe: Pipe, self: Pipe, x_u: usize, y_u: usize, x2_u: usize, y2_u: usize) bool {
    const s_x = @as(i16, @intCast(x_u));
    const s_y = @as(i16, @intCast(y_u));
    const x2 = @as(i16, @intCast(x2_u));
    const y2 = @as(i16, @intCast(y2_u));

    // std.debug.print("Check self ({d}, {d}), against neighbor ({d}, {d})\n", .{ s_x, s_y, x2, y2 });

    if (s_x == x2) {
        // std.debug.print("\tSame column...\n", .{});
        if (y2 < s_y) { // Above
            // Pipes connect?
            // std.debug.print("\t\tUp, {d}, {d} / {d} {d}\n", .{ self.y1, self.y2, pipe.y1, pipe.y2 });
            if (self.y1 != 0) {
                return self.y1 + pipe.y2 == 0;
            }
        } else { // Below
            // Pipes connect?
            // std.debug.print("\t\tDown\n", .{});
            if (self.y2 != 0) {
                return self.y2 + pipe.y1 == 0;
            }
        }
    } else if (s_y == y2) {
        // std.debug.print("\tSame row...\n", .{});
        if (x2 < s_x) { // Left
            // std.debug.print("\t\tLeft\n", .{});
            // Pipes connect?
            if (self.x1 != 0) {
                return self.x1 + pipe.x2 == 0;
            }
        } else { // Right
            // std.debug.print("\t\tRight\n", .{});
            // Pipes connect?
            if (self.x2 != 0) {
                return self.x2 + pipe.x1 == 0;
            }
        }
    }

    // Default case, not a valid neighbor
    return false;
}

fn getNeighbors(grid: std.ArrayList(std.ArrayList(Square)), x: usize, y: usize) !std.ArrayList(Square) {
    var neighbors = std.ArrayList(Square).init(std.heap.c_allocator);

    const minX = if (x > 0) x - 1 else x;
    const minY = if (y > 0) y - 1 else y;

    const maxX = std.math.clamp(x + 2, 0, grid.items[0].items.len);
    const maxY = std.math.clamp(y + 2, 0, grid.items.len);

    const self = grid.items[y].items[x];

    // std.debug.print("Get neighbors of ({d}, {d})\n", .{ x, y });
    // std.debug.print("minY: {d}, minX: {d}\n", .{ minY, minX });
    // std.debug.print("maxY: {d}, maxX: {d}\n", .{ maxY, maxX });
    for (grid.items[minY..maxY], minY..) |line, y2| {
        for (line.items[minX..maxX], minX..) |square, x2| {
            const pipe = square.pipe;
            if (x2 == x and y2 == y) {
                continue;
            }

            if (!isValidNeighbor(pipe, self.pipe, x, y, x2, y2)) {
                // std.debug.print("Invalid neighbor ({d}, {d})\n", .{ x2, y2 });
                continue;
            }

            if ((x2 == x or y2 == y) and pipe.char[0] != 32) {
                try neighbors.append(Square{ .pipe = pipe, .x = x2, .y = y2, .parent = square.parent, .visited = square.visited });
            }
        }
    }

    // for (neighbors.items) |neighbor| {
    //     std.debug.print("({d}, {d})\n", .{ neighbor.x, neighbor.y });
    // }

    return neighbors;
}

const Result = struct {
    value: u32,
    last: *Square,
};

fn floodFill(grid: std.ArrayList(std.ArrayList(Square)), x: usize, y: usize) !Result {
    // const neighbors = try getNeighbors(grid, x, y);
    // for (neighbors.items) |neighbor| {
    //     std.debug.print("({d}, {d})\n", .{ neighbor.x, neighbor.y });
    // }

    var max: u32 = 0;
    var queue = Queue(*Square).init(std.heap.c_allocator);
    var last: ?*Square = null;
    try queue.enqueue(&grid.items[y].items[x]);

    while (queue.end != null) {
        var vertex = queue.dequeue().?;

        var neighbors = try getNeighbors(grid, vertex.x, vertex.y);
        // std.debug.print("At ({d}, {d})\n", .{ vertex.x, vertex.y });
        for (neighbors.items) |neighbor| {
            if (neighbor.visited) {
                continue;
            }
            // std.debug.print("\tVisiting neighbor ({d}, {d})\n", .{ neighbor.x, neighbor.y });
            // printGridPos(grid, neighbor.x, neighbor.y, false);
            grid.items[neighbor.y].items[neighbor.x].parent = vertex;
            grid.items[neighbor.y].items[neighbor.x].visited = true;

            try queue.enqueue(&grid.items[neighbor.y].items[neighbor.x]);
        }

        grid.items[vertex.y].items[vertex.x].visited = true;

        last = vertex;
    }

    var final = last;
    if (last != null) {
        var current = last;
        while (current != null) {
            max += 1;
            current = current.?.parent;
        }

        // std.debug.print("\n", .{});
    }

    // for (neighbors.items) |neighbor| {
    //     if (did_visit) {
    //         continue;
    //     }
    //     visited.items[neighbor.y].items[neighbor.x] = true;

    //     // std.debug.print("Visiting ({d}, {d})\n", .{ neighbor.x, neighbor.y });
    //     printGridPos(grid, neighbor.x, neighbor.y);
    //     max += 1 + try floodFill(grid, visited, neighbor.x, neighbor.y);
    // }

    max -= 1;
    grid.items[y].items[x].parent = final;
    return Result{ .value = max, .last = final.? };
}

fn deepTrace(grid: std.ArrayList(std.ArrayList(Square)), s_x: usize, s_y: usize) !std.ArrayList(*Square) {
    var result = std.ArrayList(*Square).init(std.heap.c_allocator);
    try result.append(&grid.items[s_y].items[s_x]);

    const neighbors = try getNeighbors(grid, s_x, s_y);
    for (neighbors.items) |neighbor| {
        if (grid.items[neighbor.y].items[neighbor.x].visited) {
            continue;
        }

        grid.items[neighbor.y].items[neighbor.x].visited = true;
        const next = try deepTrace(grid, neighbor.x, neighbor.y);
        for (next.items) |item| {
            try result.append(item);
        }
    }

    return result;
}

fn shoelace(list: std.ArrayList(*Square)) i32 {
    var area: i32 = 0;
    var t: usize = 0;
    for (list.items, 0..) |item, i| {
        //std.debug.print("({d}, {d})\n", .{ item.x, item.y });
        const y_u = item.y;

        const y1 = @as(i16, @intCast(y_u));

        const next = if (i == list.items.len - 1) list.items[0] else list.items[i + 1];
        const prev = if (i == 0) list.items[list.items.len - 1] else list.items[i - 1];
        const n_x = @as(i32, @intCast(next.x));
        const p_x = @as(i32, @intCast(prev.x));

        const val = y1 * (p_x - n_x);
        // std.debug.print("\t{d}({d} - {d}) = {d}\n", .{ y1, p_x, n_x, val });
        area += val;
        t += 1;
    }

    // std.debug.print("\n", .{});

    std.debug.print("Traversed {d} points\n", .{t});

    const div = @divTrunc(area, 2);

    return if (div < 0) -div else div;
}

pub fn main() !void {
    const file = @embedFile("inputs/day10.txt");
    var allocator = std.heap.c_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var grid = std.ArrayList(std.ArrayList(Square)).init(allocator);
    defer grid.deinit();

    var starting_point = [2]usize{ 0, 0 };
    for (lines.items, 0..) |line, y| {
        if (line.len == 0) {
            continue;
        }
        var row = std.ArrayList(Square).init(allocator);
        for (line, 0..) |c, x| {
            const pipe = charToPipe(c);
            if (c == 83) {
                starting_point = [2]usize{ x, y };
            }
            try row.append(Square{ .pipe = pipe, .x = x, .y = y, .visited = false, .parent = null });
        }

        try grid.append(row);
    }

    // printGrid(grid);
    std.debug.print("Starts at {d}\n", .{starting_point});

    const result = try floodFill(grid, starting_point[0], starting_point[1]);

    std.debug.print("Part 1: {d}\n", .{result.value});

    // printGridRejectInvalidNeighbors(grid);

    // try printGridColorLines(grid, result.last);
    for (grid.items, 0..) |line, y| {
        for (line.items, 0..) |_, x| {
            grid.items[y].items[x].visited = false;
        }
    }

    grid.items[starting_point[1]].items[starting_point[0]].visited = true;
    std.debug.print("Running deep trace...\n", .{});
    const full_list = try deepTrace(grid, starting_point[0], starting_point[1]);
    std.debug.print("Vertexes: {d}\n", .{full_list.items.len});

    const A = shoelace(full_list);
    const b = @as(i16, @intCast(full_list.items.len));
    std.debug.print("A = {d}, b = {d}\n", .{ A, b });

    const p2_result = A - @divFloor(b, 2) + 1;
    std.debug.print("Part 2 = {d}\n", .{p2_result});

    // const x: usize = 0;
    // const y: usize = 4;
    // const neighbors = try getNeighbors(grid, x, y);

    // printGridPos(grid, x, y);
    // for (neighbors.items) |neighbor| {
    //     std.debug.print("({d}, {d})\n", .{ neighbor.x, neighbor.y });
    // }
}
