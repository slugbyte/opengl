//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");

const basic_vertex_shader_source = @embedFile("./shader/basic.vertex.glsl");
const solid_fragment_shader_source = @embedFile("./shader/red.fragment.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation
var renderer: Renderer = undefined;

pub const Renderer = struct {
    u_window: c_int,
    window_width: c_int = 0,
    window_height: c_int = 0,

    shape_vao: c_uint,
    shape_vbo: c_uint,
    fill_shader: c_uint,

    pub fn init() !Renderer {
        var shape_vao: c_uint = undefined;
        var shape_vbo: c_uint = undefined;
        c.glCreateVertexArrays(1, &shape_vao);
        c.glGenBuffers(1, &shape_vbo);

        c.glBindVertexArray(shape_vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, shape_vbo);
        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrCast(&0));
        c.glEnableVertexAttribArray(0);

        const fill_shader = try shader_program_create(basic_vertex_shader_source, solid_fragment_shader_source);
        const u_window = c.glGetUniformLocation(fill_shader, "u_window");

        return .{
            .shape_vao = shape_vao,
            .shape_vbo = shape_vbo,
            .fill_shader = fill_shader,
            .u_window = u_window,
        };
    }

    pub fn deinit(self: *Renderer) void {
        c.glDeleteBuffers(1, &self.shape_vbo);
        c.glDeleteVertexArrays(1, &self.shape_vao);
        c.glDeleteProgram(self.fill_shader);
    }

    pub fn begin(self: *Renderer) void {
        c.glUseProgram(self.fill_shader);
        c.glBindVertexArray(self.shape_vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.shape_vbo);
        c.glUniform2f(self.u_window, @floatFromInt(self.window_width), @floatFromInt(self.window_height));
    }

    pub fn end(_: *Renderer) void {
        c.glUseProgram(0);
        c.glBindVertexArray(0);
    }

    pub fn vertex_data_set(_: *Renderer, vertex_data: []const f32) void {
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(vertex_data.len * @sizeOf(f32)), @ptrCast(vertex_data.ptr), c.GL_DYNAMIC_DRAW);
    }
};

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

fn framebuffer_resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    renderer.window_width = width;
    renderer.window_height = height;
    std.debug.print("window: {d}w {d}h\n", .{ width, height });
}

pub fn draw_rect(x: f32, y: f32, width: f32, height: f32) void {
    const x0 = x;
    const y0 = y;
    const x1 = x + width;
    const y1 = y + height;

    const vertex_data: [12]f32 = .{
        x0, y0,
        x1, y0,
        x0, y1,

        x0, y1,
        x1, y0,
        x1, y1,
    };

    renderer.begin();
    renderer.vertex_data_set(vertex_data[0..]);
    c.glDrawArrays(c.GL_TRIANGLES, 0, 6);
    renderer.end();
}

const DVD = struct {
    const dvd_width = 50;
    const dvd_height = 50;

    x: f32 = 0,
    y: f32 = 0,

    x_direction: f32 = 250,
    y_direction: f32 = 250,

    fn update(self: *DVD, dt: f32) void {
        const x_border: f32 = @as(f32, @floatFromInt(renderer.window_width));
        const y_border: f32 = @as(f32, @floatFromInt(renderer.window_height));

        // update direction
        if (self.x + dvd_width > x_border or self.x < 0) {
            self.x_direction = -1 * self.x_direction;
        }

        if (self.y + dvd_height > y_border or self.y < 0) {
            self.y_direction = -1 * self.y_direction;
        }

        self.x = self.x + (dt * self.x_direction);
        self.y = self.y + (dt * self.y_direction);

        // if (self.x + dvd_width > @as(f32, @floatFromInt(renderer.window_width)) or self.x < 0) {
        //     self.x = 0;
        // }

        // if (self.y + dvd_height > @as(f32, @floatFromInt(renderer.window_height)) or self.y < 0) {
        //     self.y = 0;
        // }
    }
};

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

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var dvd = DVD{};

    const window = c.glfwCreateWindow(800, 600, "triangle", null, null);
    if (window == null) {
        std.debug.print("fuck glfw window craete failed\n", .{});
        c.glfwTerminate();
        return;
    }
    c.glfwMakeContextCurrent(window);

    renderer = try Renderer.init();

    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &framebuffer_resize_callback);

    var x: f32 = 0.0;
    var y: f32 = 0.0;
    const speed = 120;
    var last_time = c.glfwGetTime();

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const current_time = c.glfwGetTime();
        const delta_time: f32 = @floatCast(current_time - last_time);
        last_time = current_time;
        c.glfwGetWindowSize(window, @ptrCast(&win_width), @ptrCast(&win_height));

        x = x + (speed * delta_time);
        y = y + (speed * delta_time);

        renderer.begin();
        dvd.update(delta_time);
        draw_rect(dvd.x, dvd.y, DVD.dvd_width, DVD.dvd_height);
        renderer.end();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
