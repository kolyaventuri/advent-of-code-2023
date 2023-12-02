const std = @import("std");
const Loader = @import("utils/loader.zig");

pub fn main() !void {
    const lines = try Loader.loadFile("inputs/day1.txt");
    const numbers = [9][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    const staticString = "Hello";
    _ = staticString;

    var sum: i32 = 0;
    for (lines.items, 0..) |line, lineNum| {
        _ = lineNum;
        // std.debug.print("\n==Start Line \"{s}\"==\n", .{line});
        const allocator = std.heap.page_allocator;
        var list = std.ArrayList(i8).init(allocator);
        defer list.deinit();

        var i: usize = 0;
        const wordAllocator = std.heap.page_allocator;
        var word = std.ArrayList([1]u8).init(wordAllocator);
        defer word.deinit();

        // std.debug.print("\tinit word: {s}\n", .{word.items});

        while (i < line.len) {
            const char = [1]u8{line[i]};
            i += 1;
            const num = std.fmt.parseInt(i8, &char, 10) catch -1;
            // std.debug.print("Parsed {s} -> {d}\n", .{ char, num });

            if (num == -1) {
                // It's a character, not a number
                // std.debug.print("Appending {s}\n", .{&char});
                try word.append(char);
                // std.debug.print("\tnew word: {s}\n", .{word.items});

                for (numbers, 0..) |number, n| {
                    if (number.len <= word.items.len) {
                        // std.debug.print("Checking {s} for word {s}\n", .{ word.items, number });
                        var j: usize = word.items.len - 1;
                        var k: usize = 0;
                        while (k >= 0) {
                            if (j == k or number.len == k) {
                                break;
                            }
                            // std.debug.print(". j={d}, k={d}, number.len={d}\n", .{ j, k, number.len });
                            const endChar = [_]u8{number[number.len - 1 - k]};
                            const curChar = word.items[j - k];
                            // std.debug.print("Comparing {s} vs {s}({s}) for word {s}\n", .{ curChar, endChar, number, word.items });
                            if (!std.mem.eql(u8, &endChar, &curChar)) {
                                // std.debug.print(" . Did not match! Bailing early.\n", .{});
                                k = 0;
                                break;
                            }

                            // std.debug.print("\tj={d}, k={d}\n", .{ j, k });
                            k += 1;
                        }

                        //std.debug.print(" . k={d}\n", .{k});
                        if (k > 0) {
                            const toAdd: i8 = @intCast(n + 1);
                            //std.debug.print(" .WasWord: Add {d}\n", .{toAdd});
                            try list.append(toAdd);
                            //std.debug.print("Found word: {s}, compared {s} in {s}\n", .{ number, word.items, line });

                            break;
                        }
                    }
                }
                continue;
            }

            word.clearAndFree();
            // std.debug.print(" . IsNum: Add {d}\n", .{num});
            try list.append(num);
        }

        const nums = list.items;
        if (nums.len == 0) {
            continue;
        }

        //std.debug.print("Numbers in line {d}, \"{s}\": {d} -> {d}{d}\n", .{ lineNum + 1, line, nums, nums[0], nums[nums.len - 1] });
        sum += (nums[0] * 10) + nums[nums.len - 1];
    }

    std.debug.print("Result: {d}\n", .{sum});
}
