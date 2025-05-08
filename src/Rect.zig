const std = @import("std");
const window = @import("./Window.zig");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");

const Rect = @This();

pos: Vec,
size: Size,

pub fn init(pos: Vec, size: Size) Rect {
    return Rect{
        .pos = pos,
        .size = size,
    };
}

pub fn from(x: f32, y: f32, width: f32, height: f32) Rect {
    return Rect{
        .pos = Vec{ .x = x, .y = y },
        .size = Size{ .width = width, .height = height },
    };
}

pub fn contians(self: Rect, pos: Vec) bool {
    const x_max = self.pos.x + self.size.width;
    const y_max = self.pos.y + self.size.height;
    return pos.x >= self.pos.x and pos.x <= x_max and pos.y >= self.pos.y and pos.y <= y_max;
}

pub fn format(self: Rect, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("Rect(x={d} y={d} w={d} h={d})", .{ self.x, self.y, self.width, self.height });
}
