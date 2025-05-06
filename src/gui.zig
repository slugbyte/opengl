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

pub fn src_id(src: std.builtin.SourceLocation, item: ?usize) u32 {
    const _item = item orelse 0;
    var hash = fnv.init();
    hash.update(std.mem.asBytes(&src.file.ptr));
    hash.update(std.mem.asBytes(&src.module.ptr));
    hash.update(std.mem.asBytes(&src.line));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&src.column));
    hash.update(std.mem.asBytes(&_item));
    return hash.final();
}

pub const Cursor = struct {
    position: Vec,
    padding: f32 = 0.0,
    max_size: ?Size = null,
    direction: Direction = .Horizontal,

    pub const Direction = enum {
        Horizontal,
        Vertical,
    };

    pub fn init(x: f32, y: f32) Cursor {
        return Cursor{
            .position = Vec.init(x, y),
        };
    }

    pub fn next(self: *Cursor, size: Size) Vec {
        const result = self.position;

        switch (self.direction) {
            .Horizontal => {
                self.position = Vec{
                    .x = self.position.x + size.width + self.padding,
                    .y = self.position.y,
                };
            },
            .Vertical => {
                self.position = Vec{
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

pub const Stack = struct {
    cursor: Cursor,
    pos: Vec,
    size: Size,
    fill: Size,

    pub fn init(pos: Vec, size: Size, direction: Cursor.Direction) Stack {
        var cursor = Cursor.init(pos.x, pos.y);
        cursor.direction = direction;

        return Stack{
            .cursor = cursor,
            .pos = pos,
            .size = size,
            .fill = Size{ .width = 0, .height = 0 },
        };
    }

    pub fn percent_width(self: Stack, percent: f32) f32 {
        return self.size.width * percent;
    }

    pub fn percent_height(self: Stack, percent: f32) f32 {
        return self.size.height * percent;
    }

    pub fn next(self: *Stack, size: Size) Vec {
        self.fill = self.fill.add(size);
        return self.cursor.next(size);
    }

    pub fn end(_: Stack) void {
        gl.scisor_end();
    }

    pub fn is_overflow(self: Stack) bool {
        if (self.size.width < self.fill.width or self.size.height < self.fill.height) {
            return true;
        }
        return false;
    }

    // TODO: alignment ?shouldit be on the cursor?
    // alignment: Alignment = .Right,
    //
    // pub const Alignment = enum {
    //     Right,
    //     Left,
    //     // Center, ?? center seems burtal how would do ??
    // };
};

pub fn stack_h(src: SourceLocation, pos: Vec, size: Size, color: Color) !Stack {
    _ = src;
    const result = Stack.init(pos, size, .Horizontal);
    const rect = Rect.init_point_size(result.pos, result.size);
    gl.scisor_begin(rect);
    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color);
    return result;
}

pub fn stack_v(src: SourceLocation, pos: Vec, size: Size, color: Color) !Stack {
    _ = src;
    const result = Stack.init(pos, size, .Vertical);
    const rect = Rect.init_point_size(result.pos, result.size);
    gl.scisor_begin(rect);
    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color);
    gl.scisor_end();
    return result;
}

// TODO: use Box and BoxTheme
const ButtonOptions = struct {
    color_default: Color = Color.gray(200, 255),
    color_hot: Color = Color.gray(150, 255),
    color_active: Color = Color.gray(250, 255),
};

pub fn button(src: SourceLocation, cursor: *Cursor, size: Size, opt: ButtonOptions) !bool {
    const position = cursor.next(size);
    const rect = Rect.init_point_size(position, size);
    return try button_rect(src, rect, opt);
}

pub fn button_rect(src: std.builtin.SourceLocation, rect: Rect, opt: ButtonOptions) !bool {
    const id = src_id(src, null);

    var color = opt.color_default;
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
        color = opt.color_hot;
    }

    if (is_active) {
        color = opt.color_active;
    }

    if (is_hot and is_active and mouse.left_just_released) {
        result = true;
    }

    // use Box
    try gl.shader_program_set(.{ .Default = {} });
    try gl.draw_rect(rect, color);
    return result;
}

pub fn lerp(start: f32, stop: f32, t: f32) f32 {
    return start + (stop - start) * t;
}

const color_background: Color = Color.gray(200, 255);
const color_empty: Color = Color.gray(150, 255);
const color_full: Color = Color.gray(250, 255);

pub fn slider(src: std.builtin.SourceLocation, rect: Rect, value: f32) !f32 {
    const id = src_id(src, null);
    var result = value;
    if (rect.contians(mouse.pos)) {
        if (mouse.left_just_pressed) {
            id_active = id;
        }
    }

    if (id_is_active(id)) {
        const y_offset = mouse.pos.y - rect.y;
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
