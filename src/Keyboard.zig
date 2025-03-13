const Self = @This();

const std = @import("std");
const Key = @import("keys.zig").Key;
const Input = @import("Input.zig");

pub const KeySequence = struct {
    key: Key,
    modifier: ?Key = null,
};

local_buffer: [10]u8,

pub fn handleInput(result: Input.Result) ?KeySequence {
    switch (result) {
        .sequence => |buffer| {
            return handleEscapeSequence(buffer);
        },
        .char => |char| {
            return handleChars(char);
        },
    }
}

fn handleEscapeSequence(buffer: []const u8) ?KeySequence {
    if (buffer.len == 0) return null;
    if (buffer[0] != '\x1b') return null;

    switch (buffer[1]) {
        '[' => {
            switch (buffer[2]) {
                '3' => return .{ .key = Key.Delete },
                '5' => return .{ .key = Key.PgUp },
                '6' => return .{ .key = Key.PgDown },

                'A' => return .{ .key = Key.ArrowUp },
                'B' => return .{ .key = Key.ArrowDown },
                'C' => return .{ .key = Key.ArrowRight },
                'D' => return .{ .key = Key.ArrowLeft },

                else => {},
            }
        },
        else => {},
    }

    return null;
}

fn handleChars(char: u8) ?KeySequence {
    if (char > 26) {
        if (Key.fromChar(char)) |key| {
            return .{ .key = key };
        }
        return null;
    }

    // Chars from 0 to 26 is Ctrl modified a-z
    // To get actual letter from modified input, we need to flip last 2 bits

    const letter_char = controlKeyToLetter(char);
    if (Key.fromChar(letter_char)) |key| {
        return .{ .key = key, .modifier = Key.Ctrl };
    }

    return null;
}

fn controlKey(key: u8) u8 {
    return key & 0x1f;
}

fn controlKeyToLetter(char: u8) u8 {
    return char | 0b1110000;
}
