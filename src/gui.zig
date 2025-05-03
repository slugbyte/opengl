const std = @import("std");
const ctx = @import("./context.zig");
const gl = @import("./gl.zig");
const Rect = @import("./Rect.zig");
const Color = @import("./Color.zig");
const IMButton = @This();

pub const fnv = std.hash.Fnv1a_32;

const color_default: Color = Color.gray(200, 255);
const color_hover: Color = Color.gray(150, 255);
const color_active: Color = Color.gray(250, 255);

pub fn button(src: std.builtin.SourceLocation, rect: Rect) !bool {
    const id = ctx.src_to_id(src, null);
    var color = color_default;
    var result = false;
    if (rect.contians(ctx.cursor)) {
        ctx.ui_active_id = id;
        color = color_hover;
        if (ctx.mouse_left_pressed) {
            color = color_active;
        }
        if (ctx.mouse_left_just_pressed) {
            result = true;
        }
    }
    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color);
    return result;
}

const color_background: Color = Color.gray(200, 255);
const color_empty: Color = Color.gray(150, 255);
const color_full: Color = Color.gray(250, 255);

pub fn slider(src: std.builtin.SourceLocation, rect: Rect, value: f32) !f32 {
    const id = ctx.src_to_id(src, null);
    var result = value;
    if (rect.contians(ctx.cursor)) {
        if (ctx.mouse_left_just_pressed) {
            ctx.ui_active_id = id;
        }
    }
    if (!ctx.mouse_left_pressed) {
        ctx.ui_active_id = 0;
    }
    if (ctx.ui_active_id == id) {
        const y_offset = ctx.cursor.y - rect.y;
        result = y_offset / rect.height;
        result = std.math.clamp(result, 0.0, 1.0);
    }

    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color_background);
    const inner_rect = Rect.init(rect.x + 5, rect.y + 5, rect.width - 10, rect.height - 10);
    try gl.draw_rect(inner_rect, color_empty);
    const fill_rect = Rect.init(rect.x + 5, (rect.y + 5) + ((rect.height - 30) * result), rect.width - 10, 20);
    try gl.draw_rect(fill_rect, color_full);

    return result;
}
