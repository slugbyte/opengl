//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const ctx = @import("./context.zig");

const Renderer = @import("./Renderer.zig");
const Shader = @import("./Shader.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_default_source = @embedFile("./shader/fragment_default.glsl");
const shader_fragment_circle_source = @embedFile("./shader/fragment_circle.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation

fn callback_framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    ctx.window_width = width;
    ctx.window_height = height;
    ctx.window_has_resized = true;
}

fn callback_cursor_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    ctx.mouse_x = @intFromFloat(x);
    ctx.mouse_y = @intFromFloat(y);
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    if (c.glfwInit() == c.GLFW_FALSE) {
        @panic("failed to init glfw");
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(800, 600, "EMO", null, null);
    if (window == null) {
        @panic("glfw failed to create window");
    }
    c.glfwMakeContextCurrent(window);
    try ctx.init(allocator);
    // var ctx.rand: std.Random = undefined;
    // var prng = std.Random.DefaultPrng.init(100);
    // ctx.rand = prng.ctx.random();
    callback_framebuffer_resize(window, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &callback_framebuffer_resize);
    _ = c.glfwSetCursorPosCallback(window, &callback_cursor_position);

    var dot_list = std.ArrayList(Dot).init(allocator);

    for (1..100) |_| {
        try dot_list.append(Dot.init());
    }

    var shader_default = try Shader.init(.Circle, shader_vertex_source, shader_fragment_default_source);
    defer shader_default.deinit();
    var shader_circle = try Shader.init(.Circle, shader_vertex_source, shader_fragment_circle_source);
    defer shader_circle.deinit();

    // const color_bg = Color.gray(25, 255);
    // const color_fg = Color.gray(240, 255);
    //
    var fbo: c_uint = undefined;
    var tex: c_uint = undefined;
    c.glCreateFramebuffers(1, &fbo);
    c.glCreateTextures(1, ctx.window_width * ctx.window_height, &tex);

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        ctx.time_update();

        // ctx.renderer.blend_disable();
        // try ctx.renderer.begin(shader_default);
        // try ctx.renderer.draw_rect(10, 10, ctx.window_width - 20, @divFloor(ctx.window_height, 2), color_fg);
        // try ctx.renderer.end();

        if (ctx.window_width) {
            c.glDeleteTextures(1, &tex);
            c.glCreateTextures(1, ctx.window_width * ctx.window_height, &tex);
            c.glFramebufferTexture(fbo, tex, ctx.window_width, ctx.window_height);
        }

        try ctx.renderer.begin(shader_circle);
        ctx.renderer.blend_enable_alpha();
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try ctx.renderer.end();

        // pallet
        ctx.renderer.blend_disable();
        const pallet_x = @divFloor(ctx.window_width, 2) - 125;
        const pallet_y = @divFloor(ctx.window_height, 6) - 125;
        try ctx.renderer.begin(shader_default);
        try ctx.renderer.draw_rect(pallet_x, pallet_y, 250, 250, Color.Black);
        try ctx.renderer.draw_rect_color_interploate(pallet_x + 2, pallet_y + 2, 246, 246, Color.White, Color{ .r = 255 }, Color{}, Color.Black);
        try ctx.renderer.draw_rect(pallet_x, pallet_y + 255, 250, 50, Color{});
        try ctx.renderer.end();

        ctx.window_has_resized = false;

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
        ctx.debug_print();
    }
}
