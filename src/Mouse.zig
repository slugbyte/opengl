const std = @import("std");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Mouse = @This();

pos: Vec = Vec{},
left_pressed: bool = false,
left_just_pressed: bool = false,
left_just_released: bool = false,

right_pressed: bool = false,
right_just_pressed: bool = false,
right_just_released: bool = false,

// TODO: right_mouse_button
// TODO: middle_mouse_button
// TODO: scroll_wheel

pub fn update_end(self: *Mouse) void {
    self.left_just_pressed = false;
    self.left_just_released = false;
    self.right_just_pressed = false;
    self.right_just_released = false;
}

pub fn format(self: Mouse, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("Mouse(x={d} y={d}", .{ self.pos.x, self.pos.y });
    try writer.print(" left[{} JP:{} JR:{}]", .{ self.left_pressed, self.left_just_pressed, self.left_just_released });
    try writer.print(")", .{});
}
