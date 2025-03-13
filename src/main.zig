const std = @import("std");
const Terminal = @import("Terminal.zig");
const Renderer = @import("Renderer.zig");
const Keyboard = @import("Keyboard.zig");
const Key = @import("keys.zig").Key;
const Input = @import("Input.zig");
const Buffer = @import("Buffer.zig");

const Direction = enum {
    Left,
    Up,
    Down,
    Right,
};

fn isControlChar(char: u8) bool {
    // All control characters in ASCII is 0...31 and 127
    return char > 31 or char == 127;
}

fn process(key_sequence: Keyboard.KeySequence, terminal: *Terminal, renderer: *Renderer) !void {
    if (key_sequence.modifier == Key.Ctrl) {
        switch (key_sequence.key) {
            Key.q => try exit(terminal, renderer),
            else => return,
        }
    } else {
        switch (key_sequence.key) {
            Key.h, Key.ArrowLeft => moveCursor(Direction.Left, terminal),
            Key.j, Key.ArrowDown => moveCursor(Direction.Down, terminal),
            Key.k, Key.ArrowUp => moveCursor(Direction.Up, terminal),
            Key.l, Key.ArrowRight => moveCursor(Direction.Right, terminal),
            Key.PgUp => {
                for (0..terminal.size.rows) |_| {
                    moveCursor(Direction.Up, terminal);
                }
            },
            Key.PgDown => {
                for (0..terminal.size.rows) |_| {
                    moveCursor(Direction.Down, terminal);
                }
            },
            else => {},
        }
        std.debug.print("Key: {?s}\r\n", .{std.enums.tagName(Key, key_sequence.key)});
    }
}

fn moveCursor(direction: Direction, terminal: *Terminal) void {
    var cursor_pos = terminal.cursor_position;

    switch (direction) {
        Direction.Left => {
            if (cursor_pos.col > 0)
                cursor_pos.col -= 1;
        },
        Direction.Up => {
            if (cursor_pos.row > 0)
                cursor_pos.row -= 1;
        },
        Direction.Down => {
            cursor_pos.row += 1;
        },
        Direction.Right => {
            cursor_pos.col += 1;
        },
    }

    if (cursor_pos.row <= terminal.size.rows - 1) {
        terminal.cursor_position.row = cursor_pos.row;
    }

    if (cursor_pos.col <= terminal.size.cols - 1) {
        terminal.cursor_position.col = cursor_pos.col;
    }
}

fn exit(terminal: *Terminal, renderer: *Renderer) !void {
    try renderer.clearScreen();
    try terminal.exit();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdin = std.io.getStdIn();
    const stdin_reader = stdin.reader();

    const stdout = std.io.getStdOut();

    var terminal = Terminal.init(allocator, stdin, stdout);
    defer terminal.restoreOriginAttribs();
    defer terminal.deinit();
    terminal.enableRawMode();

    var renderer = Renderer.init(&terminal);
    var input = Input.init(allocator, stdin_reader);
    const file = try std.fs.openFileAbsolute(
        "/home/radion/Projects/Zig/rvim/src/Buffer.zig",
        .{ .mode = .read_only },
    );
    const buffer = try Buffer.readFrom(allocator, file);

    while (true) {
        try renderer.beginDraw();
        try renderer.writeRows(buffer);
        try renderer.commitDraw();

        if (input.read() catch null) |result| {
            defer result.deinit(allocator);
            if (Keyboard.handleInput(result)) |key| {
                try process(key, &terminal, &renderer);
            }
        }

        try terminal.update();
        try terminal.commitBuffer();
    }
}
