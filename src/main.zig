//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const c = @import("./c.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_source = @embedFile("./shader/fragment.glsl");

fn resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}

fn shader_compile(shader_type: c.GLenum, source: []const u8) !c.GLuint {
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

fn shader_program_create(vertex_source: []const u8, fragment_source: []const u8) !c.GLuint {
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

pub fn main() !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        @panic("glfw failed to init");
    }
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(800, 600, "DEMO", null, null);
    if (window == null) {
        @panic("glfw failed to create window");
    }
    c.glfwMakeContextCurrent(window);

    // set viewport and window resize callback
    resize_callback(window, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &resize_callback);

    // each vertex has (x, y, r, g, b)
    const vertex_data: [15]f32 = .{
        0.0,  0.5,  1.0, 0.0, 0.0,
        0.5,  -0.5, 0.0, 1.0, 0.0,
        -0.5, -0.5, 0.0, 0.0, 1.0,
    };

    // create vao and vbo
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    c.glGenVertexArrays(1, @ptrCast(&vao));
    c.glGenBuffers(1, @ptrCast(&vbo));
    // bind vao
    c.glBindVertexArray(vao);
    // bind vbo and set vertex data
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertex_data.len * @sizeOf(f32), @ptrCast(&vertex_data), c.GL_STATIC_DRAW);

    // set vertex attrib for location 0 (vec2 aPos)
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    // set vertex attrib for location 1 (vec3 aColor)
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(2 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // unbind vbo and vao
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // create shader program and get uniform locations
    const shader_program = try shader_program_create(shader_vertex_source, shader_fragment_source);
    defer c.glDeleteProgram(shader_program);

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // select shader
        c.glUseProgram(shader_program);
        // bind vao
        c.glBindVertexArray(vao);
        // draw triangle
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
