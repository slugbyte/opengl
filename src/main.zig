//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");

const basic_vertex_shader_source = @embedFile("./shader/basic.vertex.glsl");
const solid_fragment_shader_source = @embedFile("./shader/red.fragment.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation

pub fn shader_compile(shader_type: c.GLenum, source: []const u8) !c.GLuint {
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
                return error.shader_copile_fragment_failed;
            },
            c.GL_VERTEX_SHADER => {
                std.debug.print("ERROR: (compile_shader vertex) {s}\n", .{err_msg});
                return error.shader_copile_fragment_failed;
            },
            else => unreachable,
        };
    }
    return shader;
}

pub fn shader_program_create(vertex_source: []const u8, fragment_source: []const u8) !c.GLuint {
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
        return error.program_link_failed;
    }

    return shader_program;
}

fn framebuffer_resize_callback(_: ?*c.GLFWwindow, width: c_int, hight: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, hight);
    std.debug.print("screen_size: {d} {d}\n", .{ width, hight });
}

pub fn main() !void {
    var win_width: c_int = undefined;
    var win_height: c_int = undefined;
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    if (c.glfwInit() == c.GLFW_FALSE) {
        std.debug.print("fuck glfw failed\n", .{});
        return;
    }
    defer c.glfwTerminate();

    const window = c.glfwCreateWindow(800, 600, "triangle", null, null);
    if (window == null) {
        std.debug.print("fuck glfw window craete failed\n", .{});
        c.glfwTerminate();
        return;
    }
    c.glfwMakeContextCurrent(window);

    const triangle: [6]f32 = .{
        150.0, 100.0,
        100.0, 200.0,
        200.0, 200.0,
    };

    var vao: c_uint = undefined;
    c.glGenVertexArrays(1, @ptrCast(&vao));
    c.glBindVertexArray(vao);
    var vbo: c_uint = undefined;
    c.glGenBuffers(1, @ptrCast(&vbo));
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, triangle.len * @sizeOf(f32), &triangle, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrCast(&0));
    c.glBindVertexArray(0);

    const shader_program = try shader_program_create(basic_vertex_shader_source, solid_fragment_shader_source);
    const resolution_loc = c.glGetUniformLocation(shader_program, "u_resolution");

    c.glViewport(0, 0, win_width, win_height);
    _ = c.glfwSetFramebufferSizeCallback(window, &framebuffer_resize_callback);

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwGetWindowSize(window, @ptrCast(&win_width), @ptrCast(&win_height));

        c.glClearColor(1.0, 1.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shader_program);
        c.glUniform2f(resolution_loc, @floatFromInt(win_width), @floatFromInt(win_height));
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
