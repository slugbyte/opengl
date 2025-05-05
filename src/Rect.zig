const std = @import("std");
const Point = @import("./Point.zig");
const Size = @import("./Size.zig");

const Rect = @This();

x: f32,
y: f32,
width: f32,
height: f32,

pub fn init(x: f32, y: f32, width: f32, height: f32) Rect {
    return Rect{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
}

pub fn init_point_size(point: Point, size: Size) Rect {
    return Rect{
        .x = point.x,
        .y = point.y,
        .width = size.width,
        .height = size.height,
    };
}

pub fn contians(self: Rect, point: Point) bool {
    const x_max = self.x + self.width;
    const y_max = self.y + self.height;
    return point.x >= self.x and point.x <= x_max and point.y >= self.y and point.y <= y_max;
}

pub fn format(self: Rect, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("Rect(x={d} y={d} w={d} h={d})", .{ self.x, self.y, self.width, self.height });
}

// pub fn contains(self: *Rect, point: Point) bool {
//     return is_inside(self, point.x, point.y);
// }
