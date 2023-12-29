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

fn printGridPos(grid: std.ArrayList(std.ArrayList(Square)), x: ?usize, y: ?usize) void {
    for (grid.items, 0..) |line, y1| {
        for (line.items, 0..) |square, x1| {
            if (x1 == x and y1 == y) {
                std.debug.print("\x1B[31m", .{});
                std.debug.print("*", .{});
                std.debug.print("\x1B[0m", .{});
            } else {
                printTile(square.pipe.char);
            }
        }

        std.debug.print("\n", .{});
    }
}

fn printGrid(grid: std.ArrayList(std.ArrayList(Square))) void {
    printGridPos(grid, null, null);
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
    var neighbors = std.ArrayList(Square).init(std.heap.page_allocator);

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

fn floodFill(grid: std.ArrayList(std.ArrayList(Square)), x: usize, y: usize) !u32 {
    // const neighbors = try getNeighbors(grid, x, y);
    // for (neighbors.items) |neighbor| {
    //     std.debug.print("({d}, {d})\n", .{ neighbor.x, neighbor.y });
    // }

    var max: u32 = 0;
    var queue = Queue(*Square).init(std.heap.page_allocator);
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
            // printGridPos(grid, neighbor.x, neighbor.y);
            grid.items[neighbor.y].items[neighbor.x].parent = vertex;
            grid.items[vertex.y].items[vertex.x].visited = true;

            try queue.enqueue(&grid.items[neighbor.y].items[neighbor.x]);
        }

        last = vertex;
    }

    if (last != null) {
        var current = last;
        while (current != null) {
            max += 1;
            current = current.?.parent;
        }

        std.debug.print("\n", .{});
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

    return max - 1;
}

pub fn main() !void {
    const file = @embedFile("inputs/day10.txt");
    var allocator = std.heap.page_allocator;
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

    printGrid(grid);
    std.debug.print("Starts at {d}\n", .{starting_point});

    const result = try floodFill(grid, starting_point[0], starting_point[1]);

    std.debug.print("Result: {d}\n", .{result});

    // const x: usize = 0;
    // const y: usize = 4;
    // const neighbors = try getNeighbors(grid, x, y);

    // printGridPos(grid, x, y);
    // for (neighbors.items) |neighbor| {
    //     std.debug.print("({d}, {d})\n", .{ neighbor.x, neighbor.y });
    // }
}
