const std = @import("std");
const ctx = @import("./context.zig");

const Color = @import("./Color.zig");
const Rect = @import("./Rect.zig");
const Shader = @import("./Shader.zig");

const Button = @This();

id: u32,
rect: Rect,

color_default: Color = Color.gray(200, 255),
color_hover: Color = Color.gray(150, 255),
color_active: Color = Color.gray(250, 255),

click_callback: ?*const fn () void = null,

pub fn init(x: f32, y: f32, width: f32, height: f32) Button {
    return Button{
        .id = ctx.gui_id(),
        .rect = Rect.init(x, y, width, height),
    };
}

pub fn on_click(self: *Button, callback: *const fn () void) void {
    self.click_callback = callback;
}

pub fn render(self: *Button, shader: Shader) !void {
    var color = self.color_default;

    if (self.rect.is_point_inside(ctx.mouse_x, ctx.mouse_y)) {
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

    try ctx.renderer.begin(shader);
    try ctx.renderer.draw_rect(self.rect.x, self.rect.y, self.rect.width, self.rect.height, color);
    try ctx.renderer.end();
}
