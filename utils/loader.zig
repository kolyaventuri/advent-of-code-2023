const std = @import("std");

fn readFile(allocator: std.mem.Allocator, fileName: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

fn split(allocator: std.mem.Allocator, str: []const u8, delimiter: []const u8) !std.ArrayList([]const u8) {
    var list = std.ArrayList([]const u8).init(allocator);

    var start: usize = 0;
    while (start < str.len) {
        const end = std.mem.indexOfPos(u8, str, start, delimiter) orelse str.len;
        const token = str[start..end];
        try list.append(token);

        start = end + delimiter.len;
        // Handle the case where the last token is exactly at the end of the string
        if (start > str.len) {
            break;
        }
    }

    // Handle the case of a trailing delimiter, which should add an empty token
    if (std.mem.endsWith(u8, str, delimiter)) {
        try list.append(&[_]u8{});
    }

    return list;
}

pub fn loadFile(fileName: []const u8) !std.ArrayList([]const u8) {
    const allocator = std.heap.page_allocator;
    const fileContents = try readFile(allocator, fileName);
    return try split(allocator, fileContents, "\n");
}
