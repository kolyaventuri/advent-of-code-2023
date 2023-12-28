const std = @import("std");
const String = @import("utils/string.zig");

const face_cards = std.ComptimeStringMap(u4, .{ .{ "T", 11 }, .{ "J", 12 }, .{ "Q", 13 }, .{ "K", 14 }, .{ "A", 15 } });
const Hand = struct { cards: [5]u4, sets: [5]std.ArrayList(u4), score: u16, bid: u16 };

fn cmpCards(one: [5]u4, two: [5]u4) bool {
    for (one, two) |a, b| {
        if (a == b) {
            continue;
        }

        return a > b;
    }

    return false;
}

fn cmpHands(_: void, a: Hand, b: Hand) bool {
    if (a.score == b.score) {
        return cmpCards(a.cards, b.cards);
    }

    return a.score > b.score;
}

fn scoreHand(hand: [5]std.ArrayList(u4)) u3 {
    var score: u16 = 0;
    _ = score;
    var five_of_a_kind: u1 = 0;
    var four_of_a_kind: u1 = 0;
    var three_of_a_kind: u1 = 0;
    var pair: u2 = 0;
    var high_card: u3 = 0;

    for (hand) |h| {
        var value = h.items;
        if (value.len == 0) {
            continue;
        }

        if (value.len == 5) {
            five_of_a_kind += 1;
        }
        if (value.len == 4) {
            four_of_a_kind += 1;
        } else if (value.len == 3) {
            three_of_a_kind += 1;
        } else if (value.len == 2) {
            pair += 1;
        } else if (value.len == 1) {
            high_card += 1;
        }
    }

    if (five_of_a_kind > 0) {
        return 7;
    }

    if (four_of_a_kind > 0) {
        return 6;
    }

    if (three_of_a_kind > 0) {
        if (pair > 0) {
            return 5;
        }

        return 4;
    }

    if (pair > 1) {
        return 3;
    }

    if (pair > 0) {
        return 2;
    }

    return 1;
}

pub fn main() !void {
    const file = @embedFile("inputs/day7.txt");
    var allocator = std.heap.page_allocator;
    const lines = try String.split(allocator, file, "\n");
    defer lines.deinit();

    var hands_list = std.ArrayList(Hand).init(allocator);
    defer hands_list.deinit();

    for (lines.items) |line| {
        if (line.len == 0) {
            continue;
        }
        var hand = [_]std.ArrayList(u4){std.ArrayList(u4).init(allocator)} ** 5;
        for (hand) |h| {
            defer h.deinit();
        }
        var bid: u16 = 0;
        var index: usize = 0;
        var score: u16 = undefined;
        var cards = [5]u4{ 0, 0, 0, 0, 0 };

        for (line, 0..) |c, i| {
            const char = [1]u8{c};
            const num: ?u4 = std.fmt.parseUnsigned(u4, &char, 10) catch face_cards.get(&char) orelse null;
            // std.debug.print("num = {?}, index = {d}, bid = {d}\n", .{ num, index, bid });

            if (num == null) {
                index += 1;
                continue;
            }

            // std.debug.print("\tchar = {s}, value = {?}\n", .{ &char, num });
            const value = num.?;
            if (index == 0) {
                var j: usize = 0;
                cards[i] = value;
                while (j < hand.len) {
                    if (hand[j].items.len == 0) {
                        break;
                    }

                    if (hand[j].items[0] == value) {
                        break;
                    }
                    j += 1;
                }
                try hand[j].append(value);
                continue;
            }

            bid *= 10;
            bid += num orelse 0;
            // std.debug.print("\thand= ", .{});
            // for (hand) |h| {
            //     std.debug.print("{d} ", .{h.items});
            // }
            score = scoreHand(hand);
            // std.debug.print(", score = {d}\n", .{score});
        }

        try hands_list.append(Hand{ .cards = cards, .sets = hand, .score = score, .bid = bid });
    }

    var part1Total: u32 = 0;

    std.mem.sort(Hand, hands_list.items, {}, cmpHands);

    for (hands_list.items, 0..) |hand, i| {
        // std.debug.print("cards = {d}, hand = ", .{hand.cards});
        // for (hand.sets) |h| {
        //     std.debug.print("{d} ", .{h.items});
        // }
        const rank = @as(u16, @intCast(hands_list.items.len)) - @as(u16, @intCast(i));
        // std.debug.print(", score = {d}, bid = {d}, rank = {d}\n", .{ hand.score, hand.bid, rank });
        part1Total += @as(u32, hand.bid) * rank;
    }

    std.debug.print("Part 1: {d}\n", .{part1Total});

    var p2_hands_list = std.ArrayList(Hand).init(allocator);
    defer p2_hands_list.deinit();

    for (hands_list.items, 0..) |hand, i| {
        _ = i;
        var cards = hand.cards;
        var num_jacks: u4 = 0;
        // Drop value of 12 (J) to 1
        for (cards, 0..) |card, j| {
            if (card == 12) {
                cards[j] = 1;
                num_jacks += 1;
            }
        }

        var new_hand = [_]std.ArrayList(u4){std.ArrayList(u4).init(allocator)} ** 5;
        for (new_hand) |h| {
            defer h.deinit();
        }

        var count_jacks: u4 = 0;
        for (hand.sets, 0..) |h, j| {
            var new_set = std.ArrayList(u4).init(allocator);
            for (h.items) |item| {
                if (item == 12) {
                    count_jacks += 1;
                } else {
                    try new_set.append(item);
                }
            }

            new_hand[j] = new_set;
        }

        var max_size: u4 = 0;
        var max_index: u4 = 4;
        for (new_hand, 0..) |h, j| {
            const size: u4 = @as(u4, @intCast(h.items.len));
            if (size > max_size) {
                max_size = size;
                max_index = @as(u4, @intCast(j));
            }
        }

        var j: u4 = 0;
        while (j < count_jacks) {
            try new_hand[max_index].append(12);
            j += 1;
        }

        const score = scoreHand(new_hand);

        try p2_hands_list.append(Hand{ .cards = cards, .sets = new_hand, .score = score, .bid = hand.bid });

        // std.debug.print("{d}, jacks: {d}\n", .{ cards, count_jacks });
        // for (new_hand) |h| {
        //     std.debug.print("{d} ", .{h.items});
        // }

        // std.debug.print(" score: {d}\n", .{score});
    }

    var p2_total: u32 = 0;

    std.mem.sort(Hand, p2_hands_list.items, {}, cmpHands);

    for (p2_hands_list.items, 0..) |hand, i| {
        // std.debug.print("cards = {d}, hand = ", .{hand.cards});
        // for (hand.sets) |h| {
        //     std.debug.print("{d} ", .{h.items});
        // }
        const rank = @as(u16, @intCast(p2_hands_list.items.len)) - @as(u16, @intCast(i));
        // std.debug.print(", score = {d}, bid = {d}, rank = {d}\n", .{ hand.score, hand.bid, rank });
        p2_total += @as(u32, hand.bid) * rank;
    }

    std.debug.print("Part 2: {d}\n", .{p2_total});
}
