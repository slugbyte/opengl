//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");

const VertexBuffer = std.ArrayList(f32);

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_source = @embedFile("./shader/fragment.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation
var renderer: Renderer = undefined;
var rand: std.Random = undefined;

pub const Color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,

    pub inline fn gl_r(self: *const Color) f32 {
        return @as(f32, @floatFromInt(self.r)) / 255.0;
    }
    pub inline fn gl_g(self: *const Color) f32 {
        return @as(f32, @floatFromInt(self.g)) / 255.0;
    }
    pub inline fn gl_b(self: *const Color) f32 {
        return @as(f32, @floatFromInt(self.b)) / 255.0;
    }

    pub fn gray(value: u8) Color {
        return Color{
            .r = value,
            .g = value,
            .b = value,
        };
    }
    const White = Color{
        .r = 255,
        .g = 255,
        .b = 255,
    };

    const Black = Color{};
};

pub const Renderer = struct {
    u_window: c_int,
    window_width: c_int = 0,
    window_height: c_int = 0,
    vao: c_uint,
    vbo: c_uint,
    fill_shader: c_uint,
    vertex_count: u32 = 0,
    vertex_buffer: VertexBuffer,

    time_last: i32 = 0,
    time_delta: i32 = 0,

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        var vao: c_uint = undefined;
        var vbo: c_uint = undefined;
        c.glCreateVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);

        c.glBindVertexArray(vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        // aPos x, y
        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
        c.glEnableVertexAttribArray(0);
        // aColor rgb
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(2 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);

        const fill_shader = try shader_program_create(shader_vertex_source, shader_fragment_source);
        const u_window = c.glGetUniformLocation(fill_shader, "u_window");

        return .{
            .vao = vao,
            .vbo = vbo,
            .fill_shader = fill_shader,
            .u_window = u_window,
            .vertex_buffer = VertexBuffer.init(allocator),
        };
    }

    pub fn deinit(self: *Renderer) void {
        c.glDeleteBuffers(1, &self.vbo);
        c.glDeleteVertexArrays(1, &self.vao);
        c.glDeleteProgram(self.fill_shader);
    }

    pub fn time_update(self: *Renderer) void {
        const time_current: i32 = @intFromFloat(c.glfwGetTime() * 100.0);
        self.time_delta = time_current - self.time_last;
        self.time_last = time_current;
    }

    pub fn clear_window(_: *Renderer, color: Color) void {
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
        const vertex_data: [30]f32 = .{
            x0, y0, r, g, b,
            x1, y0, r, g, b,
            x0, y1, r, g, b,
            x0, y1, r, g, b,
            x1, y0, r, g, b,
            x1, y1, r, g, b,
        };

        try self.vertex_buffer.appendSlice(&vertex_data);
        self.vertex_count += 6;
    }

    pub fn begin(self: *Renderer) void {
        c.glUseProgram(self.fill_shader);
        c.glBindVertexArray(self.vao);
        self.vertex_count = 0;
        c.glUniform2f(self.u_window, @floatFromInt(self.window_width), @floatFromInt(self.window_height));
    }

    pub fn end(self: *Renderer) void {
        c.glUseProgram(self.fill_shader);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(self.vertex_buffer.items.len * @sizeOf(f32)), @ptrCast(self.vertex_buffer.items.ptr), c.GL_DYNAMIC_DRAW);
        c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(self.vertex_count));
        self.vertex_buffer.resize(0) catch {
            @panic("failed to resize");
        };
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

const DVD = struct {
    width: i32 = 5,
    height: i32 = 5,

    x: i32 = 0,
    y: i32 = 0,

    x_direction: i32 = 5,
    y_direction: i32 = 5,
    color: Color = Color.White,

    pub fn update(self: *DVD) void {
        const x_border: i32 = @intCast(renderer.window_width);
        const y_border: i32 = @intCast(renderer.window_height);

        if (self.x + self.width > x_border or self.x < 0) {
            self.x_direction = -1 * self.x_direction;
        }

        if (self.y + self.height > y_border or self.y < 0) {
            self.y_direction = -1 * self.y_direction;
        }

        self.x = self.x + self.x_direction;
        self.y = self.y + self.y_direction;
    }

    pub fn render(self: *DVD) void {
        renderer.draw_rect(self.x, self.y, self.width, self.height, self.color) catch {
            @panic("unable to draw rect");
        };
    }
};

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

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

    const window = c.glfwCreateWindow(800, 600, "triangle", null, null);
    if (window == null) {
        std.debug.print("fuck glfw window craete failed\n", .{});
        c.glfwTerminate();
        return;
    }
    c.glfwMakeContextCurrent(window);
    renderer = try Renderer.init(allocator);
    framebuffer_resize_callback(window, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &framebuffer_resize_callback);

    var prng = std.Random.DefaultPrng.init(100);
    rand = prng.random();
    var dvd_list = std.ArrayList(DVD).init(allocator);
    _ = rand.int(i32);

    for (1..100000) |_| {
        const gray = rand.int(u8);
        const size = rand.intRangeLessThan(i32, 5, 10);
        dvd_list.append(DVD{
            .x = rand.intRangeLessThan(i32, 0, renderer.window_width),
            .y = rand.intRangeLessThan(i32, 0, renderer.window_height),
            .width = size,
            .height = size,
            .x_direction = rand.intRangeLessThan(i32, 5, 21),
            .y_direction = rand.intRangeLessThan(i32, 5, 21),
            .color = Color.gray(gray),
        }) catch {
            @panic("ut oh");
        };
    }

    const color_bg = Color.gray(25);
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        renderer.time_update();
        renderer.clear_window(color_bg);

        renderer.begin();
        for (dvd_list.items) |*dvd_item| {
            dvd_item.update();
            dvd_item.render();
        }
        renderer.end();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
