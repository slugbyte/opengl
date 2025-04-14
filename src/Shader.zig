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

program: c.GLuint,
vao: c.GLuint,
kind: Kind,

u_window: ?c.GLint,
u_color: ?c.GLint,
u_texture: ?c.GLint,

pub fn init(kind: Kind, vertex_source: []const u8, fragment_source: []const u8) ErrorShader!Shader {
    const program = try program_create(vertex_source, fragment_source);
    const u_window = try uniform_location(program, "u_window");
    const u_color = try uniform_location(program, "u_color");
    const u_texture = try uniform_location(program, "u_texture");

    var vao: c.GLuint = undefined;
    c.glCreateVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    c.glBindVertexArray(vao);
    // aPos x, y
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);
    // aColor rgb
    c.glVertexAttribPointer(1, 4, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(2 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
    // aUV
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    return Shader{
        .program = program,
        .vao = vao,
        .kind = kind,
        .u_window = u_window,
        .u_color = u_color,
        .u_texture = u_texture,
    };
}

pub fn deinit(self: *Shader) void {
    c.glDeleteProgram(self.program);
    c.glDeleteVertexArrays(1, &self.vao);
}

pub fn use(self: *const Shader) void {
    c.glUseProgram(self.program);
    c.glBindVertexArray(self.vao);
}

pub fn use_none() void {
    c.glUseProgram(0);
    c.glBindVertexArray(0);
}

pub fn u_window_set(self: *const Shader, width: f32, height: f32) ErrorShader!void {
    if (self.u_window) |u_window| {
        c.glUniform2f(u_window, width, height);
    } else {
        return ErrorShader.UWindowNotFound;
    }
}

pub fn u_texture_set(self: *const Shader, location: i32) ErrorShader!void {
    if (self.u_texture) |u_texture| {
        c.glUniform1i(u_texture, location);
    } else {
        return ErrorShader.UWindowNotFound;
    }
}

pub fn uniform_location(program: c.GLuint, name: []const u8) ErrorShader!?c.GLint {
    const result = c.glGetUniformLocation(program, name.ptr);
    if (result == -1) {
        return null;
    }
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
