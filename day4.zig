const std = @import("std");
const String = @import("utils/string.zig");

fn readCard(card: []const u8, container: []i8) void {
    var tempSum: i8 = -1;
    var i: usize = 0;
    for (card, 0..) |c, j| {
        const num = std.fmt.parseInt(i8, &[1]u8{c}, 10) catch -1;
        // Handles the case where the first number is " 1", with that leading space
        if (num == -1 and tempSum < 0) {
            continue;
        }

        if (num > -1) {
            if (tempSum < 0) {
                tempSum = 0;
            }
            tempSum *= 10;
            tempSum += num;
        }

        if (num == -1 or j == card.len - 1) {
            container[i] = tempSum;
            tempSum = -1;
            i += 1;
            continue;
        }
    }
}

pub fn main() !void {
    const file = @embedFile("inputs/day4.txt");
    var stringAllocator = std.heap.page_allocator;
    const lines = try String.split(stringAllocator, file, "\n");
    defer lines.deinit();

    var totalScore: i32 = 0;

    for (lines.items, 0..) |line, cardNum| {
        if (line.len == 0) {
            continue;
        }
        const parts = try String.split(stringAllocator, line, ": ");
        defer parts.deinit();
        const cards = try String.split(stringAllocator, parts.items[1], " | ");

        var winningNumbers = [10]i8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
        var playNumbers = [25]i8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

        readCard(cards.items[0], &winningNumbers);
        readCard(cards.items[1], &playNumbers);

        std.debug.print("Card {d}, winning: {d}, playing: {d}\n", .{ cardNum, winningNumbers, playNumbers });
        var pow: i8 = -1;
        for (winningNumbers) |num| {
            for (playNumbers) |win| {
                if (num == 0 or win == 0) {
                    // Short-circuit during the test file
                    break;
                }
                if (num == win) {
                    pow += 1;
                    break;
                }
            }
        }

        const result = if (pow == -1) 0 else std.math.pow(i32, 2, pow);
        totalScore += result;
        std.debug.print("\tScore: {d}\n", .{result});
    }

    std.debug.print("\nPart 1: {d}\n", .{totalScore});
}
