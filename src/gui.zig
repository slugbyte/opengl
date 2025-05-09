const std = @import("std");
const gl = @import("./gl.zig");
const Mouse = @import("./Mouse.zig");
const SourceLocation = std.builtin.SourceLocation;

pub const id_src = @import("id.zig").src;

const length = @import("./length.zig");
pub const Length = length.Length;
pub const pixel = length.pixel;
pub const scale = length.scale;

pub const Size = @import("./Size.zig");
pub const Vec = @import("./Vec.zig");
pub const Rect = @import("./Vec.zig");

pub const Color = @import("./Color.zig");

pub const Box = @import("./Box.zig");
pub const BoxStyle = Box.BoxPallet;
pub const BoxOptions = Box.BoxOptions;

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
};

pub fn button_rect(src: std.builtin.SourceLocation, opt: Box.BoxOptions) !bool {
    const id = id_src(src, null);
    const rect = opt.rect;

    const pallet = opt.pallet orelse button_pallet_default;

    if (pallet.bg_default == null or pallet.bg_hot == null or pallet.bg_active == null) {
        @panic("button requires pallet with color_default color_hot and color_active");
    }

    var color = pallet.bg_default.?;
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
        color = pallet.bg_hot.?;
    }

    if (is_active) {
        color = pallet.bg_active.?;
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
