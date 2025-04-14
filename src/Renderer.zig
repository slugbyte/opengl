const std = @import("std");
const ctx = @import("./context.zig");

const c = @import("./c.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");

const Renderer = @This();
const VertexBuffer = std.ArrayList(f32);

vbo: c_uint,
vertex_count: u32 = 0,
vertex_buffer: VertexBuffer,

pub fn init(allocator: std.mem.Allocator) !Renderer {
    var vbo: c_uint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    return .{
        .vbo = vbo,
        .vertex_buffer = VertexBuffer.init(allocator),
    };
}

pub fn deinit(self: *Renderer) void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glDeleteBuffers(1, &self.vbo);
    self.vertex_buffer.deinit();
}

pub fn blend_disable(_: *const Renderer) void {
    c.glDisable(c.GL_BLEND);
}

pub fn blend_enable_alpha(_: *const Renderer) void {
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
}

pub fn begin(self: *Renderer, shader: Shader) !void {
    shader.use();
    if (shader.u_window != null) {
        try shader.u_window_set(ctx.window_width, ctx.window_height);
    }
    self.vertex_count = 0;
}

pub fn end(self: *Renderer) !void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(self.vertex_buffer.items.len * @sizeOf(f32)), @ptrCast(self.vertex_buffer.items.ptr), c.GL_DYNAMIC_DRAW);
    c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(self.vertex_count));
    try self.vertex_buffer.resize(0);
    Shader.use_none();
}

pub fn clear(_: *Renderer, color: Color) void {
    c.glClearColor(color.gl_r(), color.gl_g(), color.gl_b(), 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn draw_rect(self: *Renderer, x: f32, y: f32, width: f32, height: f32, color: Color) !void {
    const x0: f32 = x;
    const y0: f32 = y;
    const x1: f32 = x + width;
    const y1: f32 = y + height;

    const r: f32 = color.gl_r();
    const g: f32 = color.gl_g();
    const b: f32 = color.gl_b();
    const a: f32 = color.gl_a();
    // x y r g b a u v
    const vertex_data: [48]f32 = .{
        x0, y0, r, g, b, a, 1, 1,
        x1, y0, r, g, b, a, 0, 1,
        x0, y1, r, g, b, a, 1, 0,
        x0, y1, r, g, b, a, 1, 0,
        x1, y0, r, g, b, a, 0, 1,
        x1, y1, r, g, b, a, 0, 0,
    };

    try self.vertex_buffer.appendSlice(&vertex_data);
    self.vertex_count += 6;
}

pub fn draw_square(self: *Renderer, x: f32, y: f32, size: f32, color: Color) !void {
    try self.draw_rect(x, y, size, size, color);
}

pub fn draw_rect_color_interploate(self: *Renderer, x: f32, y: f32, width: f32, height: f32, color_a: Color, color_b: Color, color_c: Color, color_d: Color) !void {
    const x0: f32 = x;
    const y0: f32 = y;
    const x1: f32 = x + width;
    const y1: f32 = y + height;

    const ar: f32 = color_a.gl_r();
    const ag: f32 = color_a.gl_g();
    const ab: f32 = color_a.gl_b();
    const aa: f32 = color_a.gl_a();

    const br: f32 = color_b.gl_r();
    const bg: f32 = color_b.gl_g();
    const bb: f32 = color_b.gl_b();
    const ba: f32 = color_b.gl_a();

    const cr: f32 = color_c.gl_r();
    const cg: f32 = color_c.gl_g();
    const cb: f32 = color_c.gl_b();
    const ca: f32 = color_c.gl_a();

    const dr: f32 = color_d.gl_r();
    const dg: f32 = color_d.gl_g();
    const db: f32 = color_d.gl_b();
    const da: f32 = color_d.gl_a();
    // x y r g b a u v
    const vertex_data: [48]f32 = .{
        x0, y0, ar, ag, ab, aa, 0, 0,
        x1, y0, br, bg, bb, ba, 1, 0,
        x0, y1, cr, cg, cb, ca, 0, 1,
        x0, y1, cr, cg, cb, ca, 0, 1,
        x1, y0, br, bg, bb, ba, 1, 0,
        x1, y1, dr, dg, db, da, 1, 1,
    };

    try self.vertex_buffer.appendSlice(&vertex_data);
    self.vertex_count += 6;
}

pub fn ColorEyedroper(_: *Renderer, x: f32, y: f32) Color {
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
