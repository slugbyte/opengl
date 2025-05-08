const gl = @import("./gl.zig");
const std = @import("std");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Rect = @import("./Rect.zig");
const Color = @import("./Color.zig");
const id_src = @import("id.zig").src;
const SourceLocation = std.builtin.SourceLocation;

const Box = @This();

pub const BoxOptions = struct {
    rect: Rect,
    color: ?Color = null,
    padding: f32 = 0,
    spacing: f32 = 0,
    border_size: ?f32 = null,
    border_color: Color = Color.Black,
    allow_overflow: bool = true,
    item_index: ?usize = null,
    cursor_align: CursorAlign = .Head,
    cursor_direction: CursorDirection = .Horizontal,
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

/// NOTE: borders are on outside because if you toggle them it wont effect internal layout
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
cursor_pos: Vec,
cursor_direction: CursorDirection,
cursor_align: CursorAlign,

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
        .pos = opt.rect.pos,
        .size = opt.rect.size,
        .color = opt.color,
        .padding = opt.padding,
        .spacing = opt.spacing,
        .border_size = opt.border_size,
        .border_color = opt.border_color,
        .content_pos = content_pos,
        .content_size = content_size,
        .allow_overflow = opt.allow_overflow,
        .cursor_pos = cursor_pos,
        .cursor_align = opt.cursor_align,
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
                    .x = self.cursor_pos.x + size.width + self.spacing,
                    .y = self.cursor_pos.y,
                };
            },
            .Tail => {
                self.cursor_pos = result_pos.add_x(-1.0 * self.spacing);
            },
            .Center => {},
        },
        .Vertical => switch (self.cursor_align) {
            .Head => {
                self.cursor_pos = Vec{
                    .y = self.cursor_pos.y + size.height + self.spacing,
                    .x = self.cursor_pos.x,
                };
            },
            .Tail => {
                self.cursor_pos = Vec{
                    .y = self.cursor_pos.y - size.height - self.spacing,
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

pub fn next_fill(self: *Box, length: f32) Rect {
    return switch (self.cursor_direction) {
        .Horizontal => self.next(Size{ .width = length, .height = self.content_size.height }),
        .Vertical => self.next(Size{ .height = length, .width = self.content_size.width }),
    };
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
