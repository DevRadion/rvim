const Self = @This();

const std = @import("std");
const Terminal = @import("Terminal.zig");
const Buffer = @import("Buffer.zig");

terminal: *Terminal,

pub fn init(terminal: *Terminal) Self {
    return .{
        .terminal = terminal,
    };
}

pub fn writeRows(self: *Self, buffer: ?Buffer) !void {
    if (buffer) |buf| {
        for (0..self.terminal.size.rows) |row| {
            try self.clearLine();

            if (row < buf.lines.len and row < self.terminal.size.rows - 1) {
                try self.terminal.appendBuf(buf.lines[row]);
                try self.terminal.appendBuf("\r\n");
            } else if (row > buf.lines.len - 1 and row < self.terminal.size.rows - 1) {
                try self.terminal.appendBuf("~");
                try self.terminal.appendBuf("\r\n");
            } else {
                var status_buf: [50]u8 = undefined;

                const position_formatted = try std.fmt.bufPrint(&status_buf, "row: {d}, col: {d}", .{
                    self.terminal.cursor_position.row,
                    self.terminal.cursor_position.col,
                });

                try self.terminal.appendBuf(position_formatted);
            }
        }
    } else {
        for (0..self.terminal.size.rows) |row| {
            try self.clearLine();

            if (row < self.terminal.size.rows - 1) {
                try self.terminal.appendBuf("~");
                try self.terminal.appendBuf("\r\n");
            } else {
                var buf: [50]u8 = undefined;

                const position_formatted = try std.fmt.bufPrint(&buf, "row: {d}, col: {d}", .{
                    self.terminal.cursor_position.row,
                    self.terminal.cursor_position.col,
                });

                try self.terminal.appendBuf(position_formatted);
            }
        }
    }
}

pub fn clearLine(self: *Self) !void {
    try self.terminal.appendBuf("\x1b[K");
}

pub fn beginDraw(self: *Self) !void {
    try self.terminal.hideCursor();
    try self.terminal.setCursorTo(0, 0);
}

pub fn commitDraw(self: *Self) !void {
    try self.terminal.setCursorTo(0, 0);
    try self.terminal.showCursor();
}

pub fn refreshScreen(self: *Self) !void {
    // try self.terminal.update();
    try self.terminal.commitBuffer();
}

pub fn clearScreen(self: *Self) !void {
    try self.terminal.setCursorTo(0, 0);
    // Clears screen
    try self.terminal.appendBuf("\x1b[2J");
}
