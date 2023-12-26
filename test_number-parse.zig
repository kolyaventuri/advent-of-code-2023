const std = @import("std");
const String = @import("utils/string.zig");
const Reader = @import("utils/reader.zig");

const file = @embedFile("inputs/parse-test.txt");

test "can read and deinit a file" {
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const numberLine = try Reader.readNumbers(lines.items);
    defer numberLine.deinit();
}

test "can succesfully read all lines" {
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const numberLine = try Reader.readNumbers(lines.items);
    defer numberLine.deinit();

    try std.testing.expect(numberLine.items.len == 3);
}

test "reads the correct numbers in each line" {
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    const numberLine = try Reader.readNumbers(lines.items);
    defer numberLine.deinit();

    for (numberLine.items) |line| {
        try std.testing.expect(line.items.len == 5);
    }

    std.debug.print("Line 1:\n", .{});
    const expectedA = [5]i64{ 0, 1, 2, 3, 4 };
    for (numberLine.items[0].items, 0..) |number, i| {
        std.debug.print("\t{s}:{d} == {d}\n", .{ @typeName(@TypeOf(number)), number, expectedA[i] });
        try std.testing.expect(number == expectedA[i]);
        std.debug.print("\t... YES\n", .{});
    }
    std.debug.print("\n", .{});

    std.debug.print("Line 2:\n", .{});
    const expectedB = [5]i64{ 50, 40, 35, 27, 18 };
    for (numberLine.items[1].items, 0..) |number, i| {
        std.debug.print("\t{s}:{d} == {d}\n", .{ @typeName(@TypeOf(number)), number, expectedB[i] });
        try std.testing.expect(number == expectedB[i]);
        std.debug.print("\t... YES\n", .{});
    }
    std.debug.print("\n", .{});

    std.debug.print("Line 2:\n", .{});
    const expectedC = [5]i64{ -5, -700, -1235, -10673, 12356 };
    for (numberLine.items[2].items, 0..) |number, i| {
        std.debug.print("\t{s}:{d} == {d}\n", .{ @typeName(@TypeOf(number)), number, expectedC[i] });
        try std.testing.expect(number == expectedC[i]);
        std.debug.print("\t... YES\n", .{});
    }
    std.debug.print("\n", .{});
}
