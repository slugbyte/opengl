const std = @import("std");

var line_count: u32 = 0;

pub fn hud_start() void {
    std.debug.print("\r\n", .{});
    line_count += 1;
}

pub fn hud_println(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
    std.debug.print("\n", .{});
    line_count += 1;
}

pub fn hud_end() void {
    for (0..line_count) |_| {
        std.debug.print("\x1b[F", .{});
    }
    line_count = 0;
}

pub fn clear() void {
    std.debug.print("\x1B[2J\x1B[H", .{});
}
