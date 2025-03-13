const Self = @This();

const std = @import("std");

allocator: std.mem.Allocator,
lines: [][]u8,

pub fn readFrom(allocator: std.mem.Allocator, file: std.fs.File) !Self {
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var buffer = std.ArrayList([]u8).init(allocator);

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 4096)) |line| {
        try buffer.append(line);
    }

    return .{
        .allocator = allocator,
        .lines = try buffer.toOwnedSlice(),
    };
}
