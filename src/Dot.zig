const std = @import("std");
const ctx = @import("./context.zig");
const Color = @import("./Color.zig");
const Renderer = @import("./Renderer.zig");

const Dot = @This();

const DOT_MIN_DIRECTION = 2;
const DOT_MAX_DIRECTION = 20;

size: i32 = 100,

x: i32 = 0,
y: i32 = 0,

x_speed: i32 = 5,
y_speed: i32 = 5,

color: Color = Color.White,

pub fn init() Dot {
    const gray = ctx.rand.int(u8);
    const size = ctx.rand.intRangeLessThan(i32, 2, 100);
    // const x_flip: i32 = if (ctx.rand.boolean()) -1 else 1;
    // const y_flip: i32 = if (ctx.rand.boolean()) -1 else 1;
    return Dot{
        .x = ctx.rand.intRangeLessThan(i32, 0, ctx.window_width),
        .y = ctx.rand.intRangeLessThan(i32, 0, ctx.window_height),
        .size = size,
        // .x_speed = ctx.rand.intRangeLessThan(i32, 2, 6) * x_flip,
        .y_speed = ctx.rand.intRangeLessThan(i32, 2, 6),
        .color = Color.gray(gray, 200),
    };
}

pub fn update(self: *Dot) void {
    // if (ctx.window_has_resized) {
    if (ctx.rand.float(f32) < 0.01) {
        self.x = ctx.rand.intRangeLessThan(i32, 0, ctx.window_width);
        self.y = ctx.rand.intRangeLessThan(i32, 0, ctx.window_height);
        self.color = Color.gray(ctx.rand.int(u8), 255);
        self.size = ctx.rand.intRangeLessThan(i32, 2, 50);
    }
    if (ctx.rand.float(f32) < 0.3) {
        self.size = std.math.clamp(self.size - 1, 10, 100);
    }
    self.y = self.y + self.y_speed;
}

pub fn render(self: *Dot) !void {
    try ctx.renderer.draw_square(self.x, self.y, self.size, self.color);
}
