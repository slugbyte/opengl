const std = @import("std");
const c = @import("./c.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");

const VertexBuffer = std.ArrayList(f32);
const Renderer = @This();

window_width: c_int = 0,
window_height: c_int = 0,

vbo: c_uint,
vertex_count: u32 = 0,
vertex_buffer: VertexBuffer,

time_last: i32 = 0,
time_delta: i32 = 0,

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

pub fn begin(self: *Renderer, shader: Shader) !void {
    shader.use();
    if (shader.u_window != null) {
        try shader.u_window_set(self.window_width, self.window_height);
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

// TODO: move to window
pub fn time_update(self: *Renderer) void {
    const time_current: i32 = @intFromFloat(c.glfwGetTime() * 1000.0);
    self.time_delta = time_current - self.time_last;
    self.time_last = time_current;
}

pub fn clear(_: *Renderer, color: Color) void {
    c.glClearColor(color.gl_r(), color.gl_g(), color.gl_b(), 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn draw_rect(self: *Renderer, x: i32, y: i32, width: i32, height: i32, color: Color) !void {
    const x0: f32 = @floatFromInt(x);
    const y0: f32 = @floatFromInt(y);
    const x1: f32 = @floatFromInt(x + width);
    const y1: f32 = @floatFromInt(y + height);

    const r: f32 = color.gl_r();
    const g: f32 = color.gl_g();
    const b: f32 = color.gl_b();
    // x y r g b u v
    const vertex_data: [42]f32 = .{
        x0, y0, r, g, b, 0, 0,
        x1, y0, r, g, b, 1, 0,
        x0, y1, r, g, b, 0, 1,
        x0, y1, r, g, b, 0, 1,
        x1, y0, r, g, b, 1, 0,
        x1, y1, r, g, b, 1, 1,
    };

    try self.vertex_buffer.appendSlice(&vertex_data);
    self.vertex_count += 6;
}
