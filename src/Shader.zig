const std = @import("std");
const c = @import("./c.zig");

const Shader = @This();

const ErrorShader = error{
    FragmentCompileFailed,
    VertexCompileFailed,
    ProgramLinkFailed,
    GLInvalidValue,
    GLInvalidOperation,
    UWindowNotFound,
};

pub const Kind = enum {
    Circle,
    Rect,
    Quad,
};

id: c.GLuint,
vao: c.GLuint,
kind: Kind,

u_window: ?c.GLint,
u_color: ?c.GLint,

pub fn init(kind: Kind, vertex_source: []const u8, fragment_source: []const u8) ErrorShader!Shader {
    const id = try program_create(vertex_source, fragment_source);
    var vao: c.GLuint = undefined;
    c.glCreateVertexArrays(1, &vao);

    return Shader{
        .id = id,
        .vao = vao,
        .kind = kind,
        .u_window = null,
        .u_color = null,
    };
}

pub fn deinit(self: *Shader) void {
    c.glDeleteProgram(self.id);
}

pub fn use(self: *const Shader) void {
    c.glUseProgram(self.id);
    c.glBindVertexArray(self.vao);
}

pub fn use_none() void {
    c.glUseProgram(0);
    c.glBindVertexArray(0);
}

pub fn u_window_set(self: *const Shader, width: i32, height: i32) ErrorShader!void {
    if (self.u_window) |u_window| {
        c.glUniform2f(u_window, @floatFromInt(width), @floatFromInt(height));
    } else {
        return ErrorShader.UWindowNotFound;
    }
}

pub fn config_circle_shader(self: *Shader) !void {
    self.u_window = try self.uniform_location("u_window");

    c.glBindVertexArray(self.vao);
    // aPos x, y
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 7 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);
    // aColor rgb
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 7 * @sizeOf(f32), @ptrFromInt(2 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
    // aUV
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 7 * @sizeOf(f32), @ptrFromInt(5 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);
}

pub fn uniform_location(self: *Shader, name: []const u8) ErrorShader!c.GLint {
    const result = c.glGetUniformLocation(self.id, name.ptr);
    return switch (result) {
        c.GL_INVALID_OPERATION => ErrorShader.GLInvalidOperation,
        c.GL_INVALID_VALUE => ErrorShader.GLInvalidValue,
        else => result,
    };
}

fn shader_compile(shader_type: c.GLenum, source: []const u8) ErrorShader!c.GLuint {
    if (!(shader_type == c.GL_FRAGMENT_SHADER or shader_type == c.GL_VERTEX_SHADER)) {
        @panic("shader_type not supported");
    }
    const shader = c.glCreateShader(shader_type);
    c.glShaderSource(shader, 1, @ptrCast(&source), null);
    c.glCompileShader(shader);

    var is_ok: c.GLenum = undefined;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, @ptrCast(&is_ok));
    if (is_ok == c.GL_FALSE) {
        var err_msg: [512]u8 = undefined;
        c.glGetShaderInfoLog(shader, 512, null, &err_msg);
        return switch (shader_type) {
            c.GL_FRAGMENT_SHADER => {
                std.debug.print("ERROR: (compile_shader fragment) {s}\n", .{err_msg});
                return ErrorShader.FragmentCompileFailed;
            },
            c.GL_VERTEX_SHADER => {
                std.debug.print("ERROR: (compile_shader vertex) {s}\n", .{err_msg});
                return ErrorShader.VertexCompileFailed;
            },
            else => unreachable,
        };
    }
    return shader;
}

fn program_create(vertex_source: []const u8, fragment_source: []const u8) ErrorShader!c.GLuint {
    const vertex_shader = try shader_compile(c.GL_VERTEX_SHADER, vertex_source);
    defer c.glDeleteShader(vertex_shader);
    const fragment_shader = try shader_compile(c.GL_FRAGMENT_SHADER, fragment_source);
    defer c.glDeleteShader(fragment_shader);

    const shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, vertex_shader);
    c.glAttachShader(shader_program, fragment_shader);
    c.glLinkProgram(shader_program);

    var is_ok: c.GLenum = undefined;
    c.glGetProgramiv(shader_program, c.GL_LINK_STATUS, @ptrCast(&is_ok));

    if (is_ok == c.GL_FALSE) {
        var err_msg: [512]u8 = undefined;
        c.glGetProgramInfoLog(shader_program, 512, null, @ptrCast(&err_msg));
        std.debug.print("ERROR: (shader_program_create) {s}\n", .{err_msg});
        return ErrorShader.ProgramLinkFailed;
    }

    return shader_program;
}
