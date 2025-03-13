const Self = @This();

const std = @import("std");
const linux = std.os.linux;
const Size = @import("Size.zig");
const Position = @import("Position.zig");
const ContentRow = @import("ContentRow.zig");

const Reader = std.fs.File.Reader;
const Writer = std.fs.File.Writer;

const winsize = extern struct {
    row: u16,
    col: u16,
    xpixel: u16,
    ypixel: u16,
};

arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,

stdout: std.fs.File,
stdin: std.fs.File,

stdin_reader: Reader,
stdout_writer: Writer,

original_attribs: linux.termios,

buffer: std.ArrayList(u8),

size: Size,
cursor_position: Position,

pub fn init(allocator: std.mem.Allocator, stdin: std.fs.File, stdout: std.fs.File) Self {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_allocator = arena.allocator();

    return .{
        .arena = arena,
        .allocator = arena_allocator,

        .stdin = stdin,
        .stdout = stdout,

        .stdin_reader = stdin.reader(),
        .stdout_writer = stdout.writer(),

        .original_attribs = getTermiosAttr(),

        .buffer = std.ArrayList(u8).init(allocator),

        .size = getSize(stdout),
        .cursor_position = Position{ .row = 0, .col = 0 },
    };
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn write(self: *Self, bytes: []const u8) !void {
    _ = try self.stdout_writer.write(bytes);
}

pub fn appendBuf(self: *Self, bytes: []const u8) !void {
    try self.buffer.appendSlice(bytes);
}

pub fn commitBuffer(self: *Self) !void {
    const buffer = try self.buffer.toOwnedSlice();
    try self.write(buffer);
}

pub fn update(self: *Self) !void {
    try self.setCursorTo(self.cursor_position.row, self.cursor_position.col);
}

pub fn readKey(self: *const Self) ?u8 {
    return self.stdin_reader.readByte() catch return null;
}

pub fn exit(self: *Self) !void {
    self.restoreOriginAttribs();
    std.os.linux.exit(0);
}

pub fn restoreOriginAttribs(self: *const Self) void {
    setTermiosAttr(self.original_attribs);
}

pub fn setCursorTo(self: *Self, row: usize, col: usize) !void {
    if (row > self.size.rows - 1 or col > self.size.cols - 1) return;

    if (row == 0 and col == 0) {
        try self.appendBuf("\x1b[H");
    } else {
        const adapted_row = row + 1;
        const adapted_col = col + 1;

        var buf: [10]u8 = undefined;

        const command = try std.fmt.bufPrint(&buf, "\x1b[{d};{d}H", .{
            adapted_row,
            adapted_col,
        });
        try self.appendBuf(command);
    }
}

pub fn showCursor(self: *Self) !void {
    try self.appendBuf("\x1b[?25h");
}

pub fn hideCursor(self: *Self) !void {
    try self.appendBuf("\x1b[?25l");
}

pub fn enableRawMode(_: *const Self) void {
    var termios: linux.termios = getTermiosAttr();

    // Local flags
    //
    // Disable echoing
    termios.lflag.ECHO = false;
    // Disabled canonical mode (so we don't need to press enter when type smth)
    termios.lflag.ICANON = false;
    // Disable SIGINT (Ctrl+C, Ctrl+Z)
    termios.lflag.ISIG = false;
    // Disable Ctrl+V
    termios.lflag.IEXTEN = false;

    // Input flags
    //
    // Disable Ctrl+S (stops terminal from receiving input) and Ctrl+Q (resumes input)
    termios.iflag.IXON = false;
    // Disable translation of carriage return (13, '\r') to newline (10, '\n')
    termios.iflag.ICRNL = false;

    // Output flags
    //
    // Disable translation of newline into carriage (13, '\r') + newline (10, '\n') -> '\r\n'
    // It's gives us more control on output
    termios.oflag.OPOST = false;

    // Control characters
    //
    // Sets minimum number of characters needed, to "read" func return
    termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    // Sets maximum amount of time to wait before "read" can return
    // Value in tenths of a second (1/10) 1 = 100 ms
    termios.cc[@intFromEnum(linux.V.TIME)] = 1;

    setTermiosAttr(termios);
}

pub fn getTermiosAttr() linux.termios {
    var termios: linux.termios = undefined;
    const result = linux.tcgetattr(linux.STDIN_FILENO, &termios);
    handleTermiosError(result, @returnAddress());
    return termios;
}

pub fn setTermiosAttr(termios: linux.termios) void {
    const result = linux.tcsetattr(linux.STDIN_FILENO, linux.TCSA.FLUSH, &termios);
    handleTermiosError(result, @returnAddress());
}

fn getSize(stdout: std.fs.File) Size {
    var window_size: winsize = undefined;

    const result = linux.ioctl(stdout.handle, linux.T.IOCGWINSZ, @intFromPtr(&window_size));
    handleTermiosError(result, @returnAddress());

    return .{
        .rows = window_size.row,
        .cols = window_size.col,
    };
}

fn handleTermiosError(result_code: usize, line: usize) void {
    if (result_code != 0) {
        const errno = std.c._errno();
        std.debug.panic("Got error on line: {d} with code: {d}", .{ line, errno });
    }
}
