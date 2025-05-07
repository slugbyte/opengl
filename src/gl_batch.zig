const std = @import("std");
const c = @import("./c.zig");

const Shader = @import("./Shader.zig");
const Mesh = @import("./Mesh.zig");
const Color = @import("./Color.zig");
const VertexBuffer = std.ArrayList(f32);

const VERTEX_FLOAT_COUNT = 8;
const VERTEX_MEMORY_SIZE = VERTEX_FLOAT_COUNT * @sizeOf(f32);
const MAX_VERTEX_CAPACITY = 1000;
const MAX_MEMORY_CAPACITY = MAX_VERTEX_CAPACITY * VERTEX_MEMORY_SIZE;

var mesh: Mesh = undefined;
var vertex_count: c_int = 0;
var vertex_buffer: VertexBuffer = undefined;
var flush_count: u32 = 0;

pub fn init(allocator: std.mem.Allocator) !void {
    mesh = Mesh.init(MAX_MEMORY_CAPACITY);
    vertex_buffer = try VertexBuffer.initCapacity(allocator, MAX_MEMORY_CAPACITY);
}

pub fn deinit() void {
    vertex_buffer.deinit();
    mesh.deinit();
}

pub fn flush() !void {
    try mesh.draw_triangles(vertex_count, vertex_buffer.items);
    try vertex_buffer.resize(0);
    vertex_count = 0;
    flush_count += 1;
}

fn ensure_vertex_capacity(count: u32) !void {
    if ((MAX_VERTEX_CAPACITY - vertex_count) < count) {
        try flush();
    }
}

pub fn draw_rect(x: f32, y: f32, width: f32, height: f32, color: Color) !void {
    try ensure_vertex_capacity(6);
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
    try ensure_vertex_capacity(6);
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
