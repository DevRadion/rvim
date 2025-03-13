const Self = @This();

const std = @import("std");

const Error = error{
    ReachedMaxLen,
};

pub const Result = union(enum) {
    sequence: []const u8,
    char: u8,

    pub fn deinit(result: Result, allocator: std.mem.Allocator) void {
        switch (result) {
            .sequence => |buffer| {
                allocator.free(buffer);
            },
            else => return,
        }
    }
};

const max_buff_len: u8 = 10;

allocator: std.mem.Allocator,
stdin_reader: std.fs.File.Reader,

local_buffer: [max_buff_len]u8 = undefined,
idx: u8 = 0,
reading_escape_sequence: bool = false,

pub fn init(allocator: std.mem.Allocator, stdin_reader: std.fs.File.Reader) Self {
    return .{
        .allocator = allocator,
        .stdin_reader = stdin_reader,
    };
}

pub fn read(self: *Self) !?Result {
    if (self.idx > max_buff_len) return Error.ReachedMaxLen;

    var result: ?Result = null;

    const byte = self.stdin_reader.readByte() catch {
        // Check if we expecting escape sequence
        if (self.reading_escape_sequence == false) return null;

        result = self.collectSequence() catch null;
        self.resetLocalState();

        // Check for a sequence if got error while reading
        return result;
    };

    const is_escape_char = byte == '\x1b';

    if (is_escape_char) {
        if (self.reading_escape_sequence) {
            result = self.collectSequence() catch null;
            self.resetLocalState();
        }

        self.reading_escape_sequence = true;
    }

    if (!is_escape_char and !self.reading_escape_sequence) {
        return .{ .char = byte };
    }

    if (self.reading_escape_sequence) {
        self.local_buffer[self.idx] = byte;
        self.idx += 1;
    }

    return result;
}

fn collectSequence(self: *Self) !?Result {
    const out_buffer = try self.allocator.dupe(u8, self.local_buffer[0..self.idx]);

    // Return available filled buffer
    return .{ .sequence = out_buffer };
}

fn resetLocalState(self: *Self) void {
    self.idx = 0;
    self.reading_escape_sequence = false;
    self.local_buffer = undefined;
}
