const std = @import("std");
const gl = @import("./gl.zig");
const Mouse = @import("./Mouse.zig");
const SourceLocation = std.builtin.SourceLocation;

pub const id_src = @import("id.zig").src;

pub const Size = @import("./Size.zig");
pub const Vec = @import("./Vec.zig");
pub const Rect = @import("./Rect.zig");

pub const Color = @import("./Color.zig");

pub const Box = @import("./Box.zig");
pub const BoxStyle = Box.BoxPallet;
pub const BoxOptions = Box.BoxOptions;
pub const BoxPallet = Box.BoxPallet;

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

pub fn lerp(start: f32, stop: f32, t: f32) f32 {
    return start + (stop - start) * t;
}

pub const CursorDirection = enum {
    Horizontal,
    Vertical,
};

pub fn box(src: SourceLocation, opt: Box.BoxOptions) !Box {
    var b = Box.init(src, opt);
    try b.render();
    return b;
}

const button_pallet_default = Box.BoxPallet{
    .bg_default = Color.gray(200, 255),
    .bg_hot = Color.gray(150, 255),
    .bg_active = Color.gray(250, 255),
    .border_default = Color.Black,
    .border_hot = Color.Black,
    .border_active = Color.White,
};

pub const ButtonResult = enum {
    None,
    LeftClick,
    RightClick,
};

pub fn button(src: std.builtin.SourceLocation, opt: Box.BoxOptions) !ButtonResult {
    const id = id_src(src, opt.item_index);
    const rect = opt.rect;

    const pallet = opt.pallet orelse button_pallet_default;

    if (pallet.bg_default == null or pallet.bg_hot == null or pallet.bg_active == null) {
        @panic("button requires pallet with color_default color_hot and color_active");
    }

    if (pallet.border_default == null or pallet.border_hot == null or pallet.border_active == null) {
        @panic("button requires pallet with color_default color_hot and color_active");
    }

    var color = pallet.bg_default.?;
    var color_border = pallet.border_default.?;

    var result: ButtonResult = .None;

    if (rect.contians(mouse.pos)) {
        id_hot = id;
        if (mouse.left_just_pressed or mouse.right_just_pressed) {
            id_active = id;
        }
    } else {
        id_hot = 0;
    }

    const is_hot = id_is_hot(id);
    const is_active = id_is_active(id);

    if (is_hot or is_active) {
        color = pallet.bg_hot.?;
        color_border = pallet.border_hot.?;
    }

    if (is_hot and is_active) {
        color = pallet.bg_active.?;
        color_border = pallet.border_active.?;
    }

    if (is_hot and is_active and mouse.left_just_released) {
        result = .LeftClick;
    }

    if (is_hot and is_active and mouse.right_just_released) {
        result = .RightClick;
    }

    var box_opt = opt;
    box_opt.color = color;
    box_opt.border_color = color_border;
    _ = try box(src, box_opt);
    return result;
}

const defualt_slider_pallet: BoxPallet = .{
    .bg_default = Color.gray(200, 255),
    .bg_hot = Color.gray(150, 255),
    .bg_active = Color.gray(250, 255),
};

pub const Direction = enum {
    Horizontal,
    Vertical,
};

pub const SliderOptions = struct {
    direction: Direction = .Horizontal,
    min: f32 = 0,
    max: f32 = 0,
};

pub fn slider(src: std.builtin.SourceLocation, value: f32, s_opt: SliderOptions, opt: BoxOptions) !f32 {
    const id = id_src(src, null);
    var result = value;
    const rect = opt.rect;

    const pallet = opt.pallet orelse defualt_slider_pallet;

    if (rect.contians(mouse.pos)) {
        if (mouse.left_just_pressed) {
            id_active = id;
        }
    }

    if (id_is_active(id)) {
        switch (s_opt.direction) {
            .Horizontal => {
                const x_offset = mouse.pos.x - rect.pos.x;
                result = x_offset / (rect.size.width);
            },
            .Vertical => {
                const y_offset = mouse.pos.y - rect.pos.y;
                result = y_offset / (rect.size.height);
            },
        }
        result = std.math.clamp(result, 0.0, 1.0);
    }

    try gl.shader_program_set(.{ .Default = {} });

    _ = try box(src, opt);

    switch (s_opt.direction) {
        .Horizontal => {
            const bar_rect = Rect.from(rect.pos.x + ((rect.size.width - 10) * result), rect.pos.y, 10, rect.size.height);
            try gl.draw_rect(bar_rect, pallet.bg_active.?);
        },
        .Vertical => {
            const bar_rect = Rect.from(rect.pos.x, (rect.pos.y) + ((rect.size.height) * result), rect.size.width, 10);
            try gl.draw_rect(bar_rect, pallet.bg_active.?);
        },
    }

    return result;
}
