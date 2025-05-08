const std = @import("std");
const gl = @import("./gl.zig");
const Rect = @import("./Rect.zig");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Mouse = @import("./Mouse.zig");
const Color = @import("./Color.zig");
const IMButton = @This();
const SourceLocation = std.builtin.SourceLocation;

pub const fnv = std.hash.Fnv1a_32;

var mouse: Mouse = undefined;
var id_active: u32 = 0;
var id_hot: u32 = 0;

pub fn begin(_mouse: Mouse) void {
    mouse = _mouse;
}

pub fn end() void {
    if (mouse.left_just_released) {
        id_active = 0;
    }
}

inline fn id_is_hot(id: u32) bool {
    return id == id_hot;
}

inline fn id_is_active(id: u32) bool {
    return id == id_active;
}

// IdeaOne x y w h
// IdeaTwo pos size
// IdeaThree cursor size

pub fn id_src(src: std.builtin.SourceLocation, item_index: ?usize) u32 {
    const index = item_index orelse 0;
    var hash = fnv.init();
    hash.update(std.mem.asBytes(&src.file.ptr));
    hash.update(std.mem.asBytes(&src.module.ptr));
    hash.update(std.mem.asBytes(&src.line));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&index));
    return hash.final();
}

pub fn lerp(start: f32, stop: f32, t: f32) f32 {
    return start + (stop - start) * t;
}

pub const CursorDirection = enum {
    Horizontal,
    Vertical,
};

pub const BoxOptions = struct {
    rect: Rect,
    color: ?Color = null,
    padding: f32 = 0,
    spacing: f32 = 0,
    border_size: ?f32 = null,
    border_color: Color = Color.Black,
    allow_overflow: bool = true,
    item_index: ?usize = null,
    cursor_direction: CursorDirection = .Horizontal,
};

/// NOTE: borders are on outside because if you toggle them it wont effect internal layout
pub const Box = struct {
    // can this use Rect funcs if has pos and size? (like an interfaces)
    // is it better to have a rect
    id: u32,
    pos: Vec,
    size: Size,
    color: ?Color,
    padding: f32,
    spacing: f32,
    border_size: ?f32,
    border_color: Color,
    content_size: Size,
    content_pos: Vec,
    allow_overflow: bool,
    cursor: Vec,
    cursor_direction: CursorDirection,
    // cursor: Cursor,

    pub fn init(src: SourceLocation, opt: BoxOptions) Box {
        const content_pos = opt.rect.pos.add_value(opt.padding);
        return Box{
            .id = id_src(src, opt.item_index),
            .pos = opt.rect.pos,
            .size = opt.rect.size,
            .color = opt.color,
            .padding = opt.padding,
            .spacing = opt.spacing,
            .border_size = opt.border_size,
            .border_color = opt.border_color,
            .content_pos = content_pos,
            .content_size = opt.rect.size.add_value(-2 * opt.padding),
            .allow_overflow = opt.allow_overflow,
            .cursor = content_pos,
            .cursor_direction = opt.cursor_direction,
        };
    }

    pub fn render(self: Box) !void {
        try gl.shader_program_set(.{ .Default = {} });
        if (self.border_size) |border_size| {
            if (border_size > 0) {
                const pos = self.pos.add_value(border_size * -1);
                const size = self.size.add_value(border_size * 2);
                try gl.batch.draw_rect(pos.x, pos.y, size.width, size.height, self.border_color);
                // TODO: fix this so that border works when color is Transpaernt
            }
        }

        if (self.color) |color| {
            try gl.batch.draw_rect(self.pos.x, self.pos.y, self.size.width, self.size.height, color);
        }

        if (!self.allow_overflow) {
            gl.scisor_begin(self.pos, self.size);
        }

        try gl.batch.flush();
    }

    pub fn next(self: *Box, size: Size) Rect {
        const result_pos = self.cursor;
        switch (self.cursor_direction) {
            .Horizontal => {
                self.cursor = Vec{
                    .x = self.cursor.x + size.width + self.spacing,
                    .y = self.cursor.y,
                };
            },
            .Vertical => {
                self.cursor = Vec{
                    .y = self.cursor.y + size.height + self.spacing,
                    .x = self.cursor.x,
                };
            },
        }
        return Rect{
            .pos = result_pos,
            .size = size,
        };
    }

    pub fn next_fill(self: *Box, length: f32) Rect {
        return switch (self.cursor_direction) {
            .Horizontal => self.next(Size{ .width = length, .height = self.content_size.height }),
            .Vertical => self.next(Size{ .height = length, .width = self.content_size.width }),
        };
    }

    pub fn end(_: Box) void {
        gl.scisor_end();
    }
};

pub fn box(src: SourceLocation, opt: BoxOptions) !Box {
    var b = Box.init(src, opt);
    try b.render();
    return b;
}

// TODO: use Box and BoxTheme
const ButtonOptions = struct {
    color_default: Color = Color.gray(200, 255),
    color_hot: Color = Color.gray(150, 255),
    color_active: Color = Color.gray(250, 255),
};

pub fn button_rect(src: std.builtin.SourceLocation, opt: BoxOptions) !bool {
    const id = id_src(src, null);
    const rect = opt.rect;

    const button_options = ButtonOptions{};

    var color = button_options.color_default;
    var result = false;

    if (rect.contians(mouse.pos)) {
        id_hot = id;
        if (mouse.left_just_pressed) {
            id_active = id;
        }
    } else {
        id_hot = 0;
    }

    const is_hot = id_is_hot(id);
    const is_active = id_is_active(id);

    if (is_hot) {
        color = button_options.color_hot;
    }

    if (is_active) {
        color = button_options.color_active;
    }

    if (is_hot and is_active and mouse.left_just_released) {
        result = true;
    }

    var box_opt = opt;
    box_opt.color = color;
    // use Box
    // try gl.shader_program_set(.{ .Default = {} });
    // try gl.draw_rect(rect, color);
    _ = try box(src, box_opt);
    return result;
}

// pub fn slider(src: std.builtin.SourceLocation, rect: Rect, value: f32) !f32 {
//     const id = src_id(src, null);
//     var result = value;
//     if (rect.contians(mouse.pos)) {
//         if (mouse.left_just_pressed) {
//             id_active = id;
//         }
//     }
//
//     if (id_is_active(id)) {
//         const y_offset = mouse.pos.y - rect.y;
//         result = y_offset / rect.height;
//         result = std.math.clamp(result, 0.0, 1.0);
//     }
//
//     try gl.shader_program_set(.{ .Default = {} });
//     try gl.draw_rect(rect, color_background);
//
//     const inner_rect = Rect.init(rect.x + 5, rect.y + 5, rect.width - 10, rect.height - 10);
//     try gl.draw_rect(inner_rect, color_empty);
//
//     const bar_rect = Rect.init(rect.x + 5, (rect.y + 5) + ((rect.height - 20) * result), rect.width - 10, 10);
//     try gl.draw_rect(bar_rect, color_full);
//
//     return result;
// }
