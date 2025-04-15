const std = @import("std");
const ctx = @import("./context.zig");

const c = @import("./c.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");

const VertexBuffer = std.ArrayList(f32);

var vbo: c_uint = undefined;
var vertex_count: u32 = 0;
var vertex_buffer: VertexBuffer = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    vertex_buffer = VertexBuffer.init(allocator);
}

pub fn deinit() void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glDeleteBuffers(1, vbo);
    vertex_buffer.deinit();
}

pub fn begin() void {
    vertex_count = 0;
}

pub fn end() !void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(vertex_buffer.items.len * @sizeOf(f32)), @ptrCast(vertex_buffer.items.ptr), c.GL_DYNAMIC_DRAW);
    c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(vertex_count));
    try vertex_buffer.resize(0);
}

pub fn draw_rect(x: f32, y: f32, width: f32, height: f32, color: Color) !void {
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

    try vertex_buffer.appendSlice(&vertex_data);
    vertex_count += 6;
}

pub fn draw_square(x: f32, y: f32, size: f32, color: Color) !void {
    try draw_rect(x, y, size, size, color);
}

pub fn draw_rect_color_interploate(x: f32, y: f32, width: f32, height: f32, color_bl: Color, color_tl: Color, color_tr: Color, color_br: Color) !void {
    const x0: f32 = x;
    const y0: f32 = y;
    const x1: f32 = x + width;
    const y1: f32 = y + height;

    const ar, const ag, const ab, const aa = color_bl.gl_vertex();
    const br, const bg, const bb, const ba = color_tl.gl_vertex();
    const cr, const cg, const cb, const ca = color_tr.gl_vertex();
    const dr, const dg, const db, const da = color_br.gl_vertex();

    // TODO: fix the UV cords
    // x y r g b a u v
    const vertex_data: [48]f32 = .{
        x0, y0, ar, ag, ab, aa, 0, 0,
        x1, y0, br, bg, bb, ba, 1, 0,
        x0, y1, cr, cg, cb, ca, 0, 1,
        x0, y1, cr, cg, cb, ca, 0, 1,
        x1, y0, br, bg, bb, ba, 1, 0,
        x1, y1, dr, dg, db, da, 1, 1,
    };

    try vertex_buffer.appendSlice(&vertex_data);
    vertex_count += 6;
}
