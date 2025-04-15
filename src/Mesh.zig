const c = @import("./c.zig");
const Mesh = @This();

const ErrorMesh = error{
    CapacityExceeded,
};

vao: c_uint,
vbo: c_uint,
capacity: c_uint,

pub fn init(capacity: c_uint) Mesh {
    var vao_: c_uint = undefined;
    var vbo_: c_uint = undefined;

    c.glGenVertexArrays(1, &vao_);
    c.glBindVertexArray(vao_);

    c.glGenBuffers(1, &vbo_);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo_);
    c.glBufferData(c.GL_ARRAY_BUFFER, capacity * @sizeOf(f32), null, c.GL_DYNAMIC_DRAW);

    // aPos x, y
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);
    // aColor rgb
    c.glVertexAttribPointer(1, 4, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(2 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
    // aUV
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    c.glBindVertexArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    return Mesh{
        .vao = vao_,
        .vbo = vbo_,
        .capacity = capacity,
    };
}

pub fn deinit(self: Mesh) void {
    c.glDeleteVertexArrays(1, self.vao);
    c.glDeleteBuffers(1, self.vbo);
}

pub fn bind_vao(self: Mesh) void {
    c.glBindVertexArray(self.vao);
}

pub fn bind_vbo(self: Mesh) void {
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
}

// update the pre-allocated vbo with new vertex_data
pub fn vertex_data_update(self: Mesh, vertex_data: []const f32) ErrorMesh!void {
    if (vertex_data.len > self.capacity) {
        return ErrorMesh.CapacityExceeded;
    }
    // NOTE: remebere must rebind VBO before update data in GL_ARRAY_BUFFER
    // the vao only remembers the attibutes
    self.bind_vbo();
    c.glBufferSubData(c.GL_ARRAY_BUFFER, 0, @intCast(vertex_data.len * @sizeOf(f32)), @ptrCast(vertex_data.ptr));
}

pub fn draw_triangles(self: Mesh, vertex_count: c_int, vertex_data: []const f32) ErrorMesh!void {
    // TODO: ? should i error check if vertex_count is not divisiable by 3 ?
    self.bind_vao();
    try self.vertex_data_update(vertex_data);
    c.glDrawArrays(c.GL_TRIANGLES, 0, vertex_count);
}
