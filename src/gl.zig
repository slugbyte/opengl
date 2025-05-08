const std = @import("std");
const c = @import("./c.zig");
const window = @import("Window.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");
const Vec = @import("./Vec.zig");
const Size = @import("Size.zig");
const Rect = @import("./Rect.zig");
const Mesh = @import("./Mesh.zig");
const Texture = @import("./Texture.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_default_source = @embedFile("./shader/fragment_default.glsl");
const shader_fragment_circle_source = @embedFile("./shader/fragment_circle.glsl");
const shader_fragment_texture_source = @embedFile("./shader/fragment_texture.glsl");

var vao: c_uint = undefined;
var vbo: c_uint = undefined;

var mesh: Mesh = undefined;

var shader_default: Shader = undefined;
var shader_texture: Shader = undefined;
var shader_circle: Shader = undefined;

var blend_mode: BlendMode = .Normal;
var shader_program: ShaderProgram = .Default;

pub const batch = @import("./gl_batch.zig");

pub fn init(allocator: std.mem.Allocator) !void {
    try batch.init(allocator);
    mesh = Mesh.init(999);
    shader_default = try Shader.init(shader_vertex_source, shader_fragment_default_source);
    shader_texture = try Shader.init(shader_vertex_source, shader_fragment_texture_source);
    shader_circle = try Shader.init(shader_vertex_source, shader_fragment_circle_source);
    blend_mode_set(.Normal);
}

pub fn deinit() void {
    batch.deinit();
    shader_default.deinit();
    shader_texture.deinit();
    shader_circle.deinit();
    c.glDeleteBuffers(1, &vbo);
}

pub fn blend_mode_set(mode: BlendMode) void {
    c.glEnable(c.GL_BLEND);
    blend_mode = mode;
    switch (mode) {
        .Disable => c.glDisable(c.GL_BLEND),
        .Normal => c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA),
        .Overlay => c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA),
        .Multiply => c.glBlendFunc(c.GL_DST_COLOR, c.GL_ONE_MINUS_SRC_ALPHA),
        .Add => c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE),
        .Subtract => {
            c.glBlendFuncSeparate(c.GL_SRC_ALPHA, c.GL_ONE, c.GL_ONE, c.GL_ONE_MINUS_SRC_ALPHA);
            c.glBlendEquation(c.GL_FUNC_REVERSE_SUBTRACT);
        },
    }
}

pub fn shader_program_set(program: ShaderProgram) !void {
    shader_program = program;
    switch (program) {
        .Default => {
            shader_default.use();
            try shader_default.u_window_set(window.size.width, window.size.height);
        },
        .Circle => {
            shader_circle.use();
            try shader_circle.u_window_set(window.size.width, window.size.height);
        },
        .Texture => |texture| {
            shader_texture.use();
            try shader_texture.u_window_set(window.size.width, window.size.height);
            try shader_texture.u_texture_set(texture);
        },
    }
}

pub fn clear(color: Color) void {
    c.glClearColor(color.gl_r(), color.gl_g(), color.gl_b(), 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn scisor_begin_rect(rect: Rect) void {
    c.glEnable(c.GL_SCISSOR_TEST);
    // flip y axis for opengl cords
    const y: f32 = (window.size.height - 1) - rect.y - rect.height + 1;
    c.glScissor(@intFromFloat(rect.x), @intFromFloat(y), @intFromFloat(rect.width), @intFromFloat(rect.height));
}

pub fn scisor_begin(pos: Vec, size: Size) void {
    c.glEnable(c.GL_SCISSOR_TEST);
    // flip y axis for opengl cords
    const y: f32 = (window.size.height - 1) - pos.y - size.height + 1;
    c.glScissor(@intFromFloat(pos.x), @intFromFloat(y), @intFromFloat(size.width), @intFromFloat(size.height));
}

pub fn scisor_end() void {
    c.glDisable(c.GL_SCISSOR_TEST);
}

pub fn eyedroper(x: f32, y: f32) Color {
    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(c.glfwGetCurrentContext(), &width, &height);

    const read_x: c_int = @intFromFloat(x);
    const read_y: c_int = height - @as(c_int, @intFromFloat(y));
    var rgba: [4]u8 = .{ 0, 0, 0, 0 };

    c.glReadPixels(read_x, read_y, 1, 1, c.GL_RGBA, c.GL_UNSIGNED_BYTE, @ptrCast(&rgba));

    std.debug.print("color: {any}", .{rgba});
    return Color{};
}

pub fn draw_rect(rect: Rect, color: Color) !void {
    const x0: f32 = rect.pos.x;
    const y0: f32 = rect.pos.y;
    const x1: f32 = rect.pos.x + rect.size.width;
    const y1: f32 = rect.pos.y + rect.size.height;

    const r, const g, const b, const a = color.gl_vertex();
    // x y r g b a u v
    const vertex_data: [48]f32 = .{
        x0, y0, r, g, b, a, 1, 1,
        x1, y0, r, g, b, a, 0, 1,
        x0, y1, r, g, b, a, 1, 0,
        x0, y1, r, g, b, a, 1, 0,
        x1, y0, r, g, b, a, 0, 1,
        x1, y1, r, g, b, a, 0, 0,
    };
    try mesh.draw_triangles(6, &vertex_data);
}

const BlendMode = enum {
    Disable,
    Normal,
    Overlay,
    Add,
    Subtract,
    Multiply,
};

const ShaderProgram = union(enum) {
    Default: void,
    Circle: void,
    Texture: Texture,
};
