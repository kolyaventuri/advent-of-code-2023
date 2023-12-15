const std = @import("std");

pub fn readNumberLine(line: []const u8) !std.ArrayList(i64) {
    var allocator = std.heap.page_allocator;
    var num_list = std.ArrayList(i64).init(allocator);

    var num: i64 = 0;
    var is_negative: bool = false;
    for (line, 0..) |char, i| {
        if (char == 45) {
            is_negative = true;
            continue;
        }

        const res = std.fmt.parseInt(i64, &[1]u8{char}, 10) catch -1;

        if (res > -1) {
            num *= 10;
            num += res;
        }

        if (res == -1 or i == line.len - 1) {
            if (is_negative) {
                num = -num;
            }
            try num_list.append(num);
            num = 0;
            is_negative = false;
        }
    }

    return num_list;
}

const Result = struct {
    _list: std.ArrayList(std.ArrayList(i64)),
    items: []std.ArrayList(i64),

    pub fn deinit(self: Result) void {
        for (self.items) |item| {
            item.deinit();
        }

        self._list.deinit();
    }
};

pub fn readNumbers(lines: [][]const u8) !Result {
    var allocator = std.heap.page_allocator;
    var line_list = std.ArrayList(std.ArrayList(i64)).init(allocator);

    for (lines) |line| {
        if (line.len == 0) {
            continue;
        }
        const result = try readNumberLine(line);
        std.debug.print("\n", .{});
        try line_list.append(result);
    }

    const res = Result{ ._list = line_list, .items = line_list.items };
    return res;
}
