const std = @import("std");
const ctx = @import("./context.zig");
const gl = @import("gl.zig");

const Color = @import("./Color.zig");
const Rect = @import("./Rect.zig");
const Shader = @import("./Shader.zig");

const Button = @This();

rect: Rect,

color_default: Color = Color.gray(200, 255),
color_hover: Color = Color.gray(150, 255),
color_active: Color = Color.gray(250, 255),

click_callback: ?*const fn () void = null,

pub fn init(x: f32, y: f32, width: f32, height: f32) Button {
    return Button{
        .rect = Rect.init(x, y, width, height),
    };
}

pub fn on_click(self: *Button, callback: *const fn () void) void {
    self.click_callback = callback;
}

pub fn render(self: *Button) !void {
    var color = self.color_default;
    if (self.rect.contians(ctx.cursor)) {
        color = self.color_hover;
        if (ctx.mouse_left_pressed) {
            color = self.color_active;
        }
        if (ctx.mouse_left_just_pressed) {
            if (self.click_callback) |callback| {
                callback();
            }
        }
    }

    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(self.rect, color);
}
