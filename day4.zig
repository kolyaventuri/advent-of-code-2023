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
    var card_allocator = std.heap.page_allocator;
    var card_list = std.ArrayList(i32).init(card_allocator);
    for (0..lines.items.len - 1) |_| {
        try card_list.append(1);
    }

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

        //std.debug.print("Card {d} (have: {d}), winning: {d}, playing: {d}\n", .{ cardNum + 1, card_list.items[cardNum], winningNumbers, playNumbers });
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

        if (pow > -1) {
            const times: i32 = if (card_list.items[cardNum] == 0) 1 else card_list.items[cardNum];
            const times_usize = @as(usize, @intCast(times));
            //std.debug.print("\ttimes_usize: {d}\n", .{times_usize});
            for (0..times_usize) |_| {
                const pow_pos = if (pow < 0) 0 else pow;
                const max: usize = cardNum + @as(usize, @intCast(pow_pos)) + 2;
                for ((cardNum + 1)..max) |index| {
                    //std.debug.print("\tWins card {d}, now have {d}\n", .{ index + 1, card_list.items[index] + 1 });
                    card_list.items[index] += 1;
                }
            }
        }

        const result = if (pow == -1) 0 else std.math.pow(i32, 2, pow);
        totalScore += result;
        //std.debug.print("\tScore: {d}\n", .{result});
    }

    std.debug.print("\nPart 1: {d}\n", .{totalScore});

    var total_cards: i32 = 0;
    for (card_list.items) |card| {
        total_cards += card;
    }
    std.debug.print("Part 2: {d}\n", .{total_cards});
}
