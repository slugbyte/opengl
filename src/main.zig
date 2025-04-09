//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const c = @import("./c.zig");

var window_width: c_int = 800.0;
var window_height: c_int = 600.0;
var mouse_x: f64 = 1.0;
var mouse_y: f64 = 1.0;
var vao: c_uint = undefined;
var vbo: c_uint = undefined;

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_source = @embedFile("./shader/fragment.glsl");

fn debug_state() void {
    std.debug.print("(window {d}w {d}h) (mouse {d}x {d}y)\r", .{ window_width, window_height, mouse_x, mouse_y });
}

fn framebuffer_resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    window_width = width;
    window_height = height;
}

fn mouse_update(window: ?*c.GLFWwindow) void {
    c.glfwGetCursorPos(window, &mouse_x, &mouse_y);

    const width: f64 = @as(f64, @floatFromInt(window_width));
    const height: f64 = @as(f64, @floatFromInt(window_height));

    if (mouse_x < 0) {
        mouse_x = 0;
    }
    if (mouse_x > width) {
        mouse_x = width;
    }
    if (mouse_y < 0) {
        mouse_y = 0;
    }
    if (mouse_y > height) {
        mouse_y = height;
    }
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

/// set GL_ARRAY_BUFFER to a big triangle centerd on the screen using x,y pixel cordinates
/// based on window_width and window_height
fn triangle_vertex_data_set() void {
    const y1: f32 = @as(f32, @floatFromInt(window_height)) * 0.2;
    const y2: f32 = @as(f32, @floatFromInt(window_height)) * 0.8;

    const x1: f32 = @as(f32, @floatFromInt(window_width)) * 0.5;
    const x2: f32 = @as(f32, @floatFromInt(window_width)) * 0.2;
    const x3: f32 = @as(f32, @floatFromInt(window_width)) * 0.8;
    const vertex_data: [6]f32 = .{
        x1, y1,
        x2, y2,
        x3, y2,
    };
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertex_data.len * @sizeOf(f32), &vertex_data, c.GL_DYNAMIC_DRAW);
}

pub fn main() !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        @panic("glfw failed to init");
    }
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(window_width, window_height, "DEMO", null, null);
    if (window == null) {
        @panic("glfw failed to create window");
    }
    c.glfwMakeContextCurrent(window);

    // set viewport
    framebuffer_resize_callback(window, window_width, window_height);
    _ = c.glfwSetFramebufferSizeCallback(window, &framebuffer_resize_callback);

    c.glGenVertexArrays(1, @ptrCast(&vao));
    c.glGenBuffers(1, @ptrCast(&vbo));

    // bind vao
    c.glBindVertexArray(vao);
    // bind vbo and set vertex data
    triangle_vertex_data_set();
    // set vertex attrib for location 0
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrCast(&0));
    c.glEnableVertexAttribArray(0);

    // unbind vbo and vao
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // create shader program and get uniform locations
    const shader_program = try shader_program_create(shader_vertex_source, shader_fragment_source);
    defer c.glDeleteProgram(shader_program);
    const u_window = c.glGetUniformLocation(shader_program, "u_window");
    const u_color = c.glGetUniformLocation(shader_program, "u_color");

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        // get glfw state
        mouse_update(window);

        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // select shader
        c.glUseProgram(shader_program);
        // set uniforms
        c.glUniform2f(u_window, @floatFromInt(window_width), @floatFromInt(window_height));
        const color_r: f32 = @as(f32, @floatCast(mouse_x)) / @as(f32, @floatFromInt(window_width));
        const color_g: f32 = @as(f32, @floatCast(mouse_y)) / @as(f32, @floatFromInt(window_height));
        const color_b: f32 = 1.0 - (color_r + color_g / 2.0);
        c.glUniform3f(u_color, color_r, color_g, color_b);
        // bind vao
        c.glBindVertexArray(vao);
        // update GL_ARRAY_BUFFER
        triangle_vertex_data_set();
        // draw triangle
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
        debug_state();
    }
}
