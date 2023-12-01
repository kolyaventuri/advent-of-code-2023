const std = @import("std");
const Loader = @import("utils/loader.zig");

pub fn main() !void {
    const lines = try Loader.loadFile("inputs/day1.txt");

    var sum: i32 = 0;
    for (lines.items) |line| {
        const allocator = std.heap.page_allocator;
        var list = std.ArrayList(i8).init(allocator);
        defer list.deinit();

        var i: usize = 0;
        while (i < line.len) {
            const char = [_]u8{line[i]};
            i += 1;
            const num = std.fmt.parseInt(i8, &char, 10) catch -1;

            if (num == -1) {
                continue;
            }

            try list.append(num);
        }

        const nums = list.items;
        if (nums.len == 0) {
            continue;
        }

        sum += (nums[0] * 10) + nums[nums.len - 1];
    }

    std.debug.print("Part 1: {d}\n", .{sum});
}
