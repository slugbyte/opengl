//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const Renderer = @import("./Renderer.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_source = @embedFile("./shader/fragment.glsl");

// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation
var renderer: Renderer = undefined;
var rand: std.Random = undefined;
var is_resize: bool = false;

fn framebuffer_resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    renderer.window_width = width;
    renderer.window_height = height;
    is_resize = true;
    std.debug.print("window: {d}w {d}h\n", .{ width, height });
}

const DVD = struct {
    width: i32 = 100,
    height: i32 = 100,

    x: i32 = 0,
    y: i32 = 0,
    // is_visable: bool = false,

    x_direction: i32 = 5,
    y_direction: i32 = 5,
    color: Color = Color.White,

    pub fn update(self: *DVD) void {
        if (is_resize) {
            self.x = rand.intRangeLessThan(i32, 0, renderer.window_width);
            self.y = rand.intRangeLessThan(i32, 0, renderer.window_height);
        }
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

    const window = c.glfwCreateWindow(800, 600, "EMO", null, null);
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

    for (1..100) |_| {
        const gray = rand.int(u8);
        const size = rand.intRangeLessThan(i32, 5, 10);
        const x_flip: i32 = if (rand.boolean()) -1 else 1;
        const y_flip: i32 = if (rand.boolean()) -1 else 1;
        try dvd_list.append(DVD{
            .x = rand.intRangeLessThan(i32, 0, renderer.window_width),
            .y = rand.intRangeLessThan(i32, 0, renderer.window_height),
            .width = size,
            .height = size,
            .x_direction = rand.intRangeLessThan(i32, 2, 6) * x_flip,
            .y_direction = rand.intRangeLessThan(i32, 2, 6) * y_flip,
            .color = Color.gray(gray),
        });
    }

    var shader_circle = try Shader.init(.Circle, shader_vertex_source, shader_fragment_source);
    try shader_circle.config_circle_shader();

    const color_bg = Color.gray(25);
    // renderer.clear(color_bg);
    // var time_clear: i32 = 0;
    // var clear_count: u8 = 0;
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        renderer.time_update();
        // time_clear += renderer.time_delta;
        // if (time_clear > 2000) {
        // clear_count = 2;
        // time_clear = 0;
        // }

        // if (clear_count > 0) {
        //     is_resize = true;
        //     renderer.clear(color_bg);
        //     clear_count -= 1;
        // }

        renderer.clear(color_bg);
        try renderer.begin(shader_circle);
        try renderer.draw_rect(10, 10, 100, 200, Color.White);
        for (dvd_list.items) |*dvd_item| {
            dvd_item.update();
            dvd_item.render();
        }
        try renderer.end();
        is_resize = false;

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
