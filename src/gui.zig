const std = @import("std");
const ctx = @import("./context.zig");
const gl = @import("./gl.zig");
const Rect = @import("./Rect.zig");
const Point = @import("./Point.zig");
const Size = @import("./Size.zig");
const Color = @import("./Color.zig");
const IMButton = @This();
const SourceLocation = std.builtin.SourceLocation;

pub const fnv = std.hash.Fnv1a_32;

pub const Cursor = struct {
    position: Point,
    padding: f32 = 10.0,
    max_size: ?Size = null,
    direction: Direction = .Horizontal,

    pub const Direction = enum {
        Horizontal,
        Vertical,
    };

    pub fn init(x: f32, y: f32) Cursor {
        return Cursor{
            .position = Point.init(x, y),
        };
    }

    pub fn get_position(self: *Cursor, size: Size) Point {
        const result = self.position;

        switch (self.direction) {
            .Horizontal => {
                self.position = Point{
                    .x = self.position.x + size.width + self.padding,
                    .y = self.position.y,
                };
            },
            .Vertical => {
                self.position = Point{
                    .y = self.position.y + size.height + self.padding,
                    .x = self.position.x,
                };
            },
        }
        return result;
    }

    pub fn switch_direction(self: *Cursor) void {
        self.direction = switch (self.direction) {
            .Horizontal => .Vertical,
            .Vertical => .Horizontal,
        };
    }
};

pub fn cursor_button(src: SourceLocation, cursor: *Cursor, size: Size) !bool {
    var color = color_default;
    var result = false;

    const id = ctx.src_to_id(src, null);

    const position = cursor.get_position(size);
    const rect = Rect.init_point_size(position, size);

    if (rect.contians(ctx.cursor)) {
        ctx.ui_hot_id = id;
        if (ctx.mouse_left_just_pressed) {
            ctx.ui_active_id = id;
        }
    } else {
        ctx.ui_hot_id = 0;
    }

    const is_hot = ctx.id_is_hot(id);
    const is_active = ctx.id_is_active(id);

    if (is_hot) {
        color = color_hover;
    }

    if (is_active) {
        color = color_active;
    }

    if (is_hot and is_active and ctx.mouse_left_just_released) {
        result = true;
    }

    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color);
    return result;
}

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

    if (ctx.ui_active_id == id) {
        const y_offset = ctx.cursor.y - rect.y;
        result = y_offset / rect.height;
        result = std.math.clamp(result, 0.0, 1.0);
    }

    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color_background);

    const inner_rect = Rect.init(rect.x + 5, rect.y + 5, rect.width - 10, rect.height - 10);
    try gl.draw_rect(inner_rect, color_empty);

    const bar_rect = Rect.init(rect.x + 5, (rect.y + 5) + ((rect.height - 20) * result), rect.width - 10, 10);
    try gl.draw_rect(bar_rect, color_full);

    return result;
}
