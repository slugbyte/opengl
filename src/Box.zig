const gl = @import("./gl.zig");
const std = @import("std");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Rect = @import("./Rect.zig");
const Color = @import("./Color.zig");
const id_src = @import("id.zig").src;
const SourceLocation = std.builtin.SourceLocation;
const Length = @import("length.zig").Length;
const Box = @This();

pub const BoxOptions = struct {
    rect: Rect,
    name: ?[]const u8 = null,
    item_index: ?usize = null,
    padding: f32 = 0,
    color: ?Color = null,
    border_size: ?f32 = null,
    border_color: Color = Color.Black,
    allow_overflow: bool = true,
    cursor_align: CursorAlign = .Head,
    cursor_direction: CursorDirection = .Horizontal,
    cursor_spacing: f32 = 0,
    pallet: ?BoxPallet = null,
};

pub const CursorDirection = enum {
    Horizontal,
    Vertical,
};

pub const CursorAlign = enum {
    Head,
    Tail,
    Center,
};

pub const BoxPallet = struct {
    bg_default: ?Color = null,
    bg_hot: ?Color = null,
    bg_active: ?Color = null,
    bg_disable: ?Color = null,
    bg_error: ?Color = null,

    fg_default: ?Color = null,
    fg_hot: ?Color = null,
    fg_active: ?Color = null,
    fg_disable: ?Color = null,
    fg_error: ?Color = null,

    border_default: ?Color = null,
    border_hot: ?Color = null,
    border_active: ?Color = null,
    border_disable: ?Color = null,
    border_error: ?Color = null,
};

/// NOTE: borders are on outside because if you toggle them it wont effect internal layout
// can this use Rect funcs if has pos and size? (like an interfaces)
// is it better to have a rect
id: u32,
name: ?[]const u8,
pos: Vec,
size: Size,
padding: f32,
color: ?Color,
border_size: ?f32,
border_color: Color,
content_size: Size,
content_pos: Vec,
allow_overflow: bool,
cursor_pos: Vec,
cursor_spacing: f32,
cursor_align: CursorAlign,
cursor_direction: CursorDirection,

pub fn init(src: SourceLocation, opt: BoxOptions) Box {
    const content_pos = opt.rect.pos.add_value(opt.padding);
    const content_size = opt.rect.size.add_value(-2 * opt.padding);

    const cursor_pos = switch (opt.cursor_direction) {
        .Vertical => switch (opt.cursor_align) {
            .Head => content_pos,
            .Tail => content_pos.add_y(content_size.height),
            .Center => content_pos.add_y(content_size.height / 2),
        },
        .Horizontal => switch (opt.cursor_align) {
            .Head => content_pos,
            .Tail => content_pos.add_x(content_size.width),
            .Center => content_pos.add_x(content_size.width / 2),
        },
    };

    return Box{
        .id = id_src(src, opt.item_index),
        .name = opt.name,
        .pos = opt.rect.pos,
        .size = opt.rect.size,
        .padding = opt.padding,
        .border_size = opt.border_size,
        .border_color = opt.border_color,
        .color = opt.color,
        .content_pos = content_pos,
        .content_size = content_size,
        .allow_overflow = opt.allow_overflow,
        .cursor_pos = cursor_pos,
        .cursor_align = opt.cursor_align,
        .cursor_spacing = opt.cursor_spacing,
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
    const result_pos = switch (self.cursor_direction) {
        .Horizontal => switch (self.cursor_align) {
            .Head => self.cursor_pos.copy(),
            .Tail => self.cursor_pos.add_x(size.width * -1),
            .Center => self.cursor_pos.add_x(-1.0 * (size.width / 2)),
        },
        .Vertical => switch (self.cursor_align) {
            .Head => self.cursor_pos.copy(),
            .Tail => self.cursor_pos.add_y(size.height * -1),
            .Center => self.cursor_pos.add_y(-1.0 * (size.height / 2)),
        },
    };

    switch (self.cursor_direction) {
        .Horizontal => switch (self.cursor_align) {
            .Head => {
                self.cursor_pos = Vec{
                    .x = self.cursor_pos.x + size.width + self.cursor_spacing,
                    .y = self.cursor_pos.y,
                };
            },
            .Tail => {
                self.cursor_pos = result_pos.add_x(-1.0 * self.cursor_spacing);
            },
            .Center => {},
        },
        .Vertical => switch (self.cursor_align) {
            .Head => {
                self.cursor_pos = Vec{
                    .y = self.cursor_pos.y + size.height + self.cursor_spacing,
                    .x = self.cursor_pos.x,
                };
            },
            .Tail => {
                self.cursor_pos = Vec{
                    .y = self.cursor_pos.y - size.height - self.cursor_spacing,
                    .x = self.cursor_pos.x,
                };
            },
            .Center => {},
        },
    }
    return Rect{
        .pos = result_pos,
        .size = size,
    };
}

pub fn space_x(self: *Box, amount: f32) void {
    self.cursor_pos.x += amount;
}

pub fn space_y(self: *Box, amount: f32) void {
    self.cursor_pos.x += amount;
}

pub fn width_percent(self: *Box, percent: f32) f32 {
    return switch (self.cursor_direction) {
        .Horizontal => self.content_size.width * percent - self.cursor_spacing * percent,
        .Vertical => self.content_size.width * percent,
    };
}

pub fn length_width(self: Box, length: Length) f32 {
    return switch (length) {
        .Scale => |value| value * self.content_size.width,
        .Pixel => |value| value,
    };
}

pub fn length_height(self: Box, length: Length) f32 {
    return switch (length) {
        .Scale => |value| value * self.content_size.height,
        .Pixel => |value| value,
    };
}

pub fn height_percent(self: Box, percent: f32) f32 {
    return switch (self.cursor_direction) {
        .Vertical => self.content_size.height * percent - self.cursor_spacing * percent,
        .Horizontal => self.content_size.width * percent,
    };
}

pub fn next_fill(self: *Box, length: Length) Rect {
    return switch (self.cursor_direction) {
        .Horizontal => {
            return self.next(Size{ .width = self.length_width(length), .height = self.content_size.height });
        },
        .Vertical => self.next(Size{ .height = self.length_height(length), .width = self.content_size.width }),
    };
}

pub fn next_length(self: *Box, width: Length, height: Length) Rect {
    const width_value = switch (width) {
        .Pixel => |value| value,
        .Scale => |value| self.content_size.width * value,
    };
    const height_value = switch (height) {
        .Pixel => |value| value,
        .Scale => |value| self.content_size.height * value,
    };

    return self.next(Size{ .width = width_value, .height = height_value });
}

pub fn center_rect(self: Box, size: Size) Rect {
    return Rect{
        .pos = self.content_pos.add(Vec{
            .x = self.content_size.width / 2 - size.width / 2,
            .y = self.content_size.height / 2 - size.height / 2,
        }),
        .size = size,
    };
}

pub fn end(_: Box) void {
    gl.scisor_end();
}
