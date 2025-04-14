//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const ctx = @import("./context.zig");

const Renderer = @import("./Renderer.zig");
const Shader = @import("./Shader.zig");
const Framebuffer = @import("./Framebuffer.zig");
const Texture = @import("./Texture.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");

const shader_vertex_source = @embedFile("./shader/vertex.glsl");
const shader_fragment_default_source = @embedFile("./shader/fragment_default.glsl");
const shader_fragment_circle_source = @embedFile("./shader/fragment_circle.glsl");
const shader_fragment_texture_source = @embedFile("./shader/fragment_texture.glsl");
// 1) create a triangle using pixelspace that is solid color
// 2) make a gradient using vector interpolation

fn callback_framebuffer_resize(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    ctx.window_width = @floatFromInt(width);
    ctx.window_height = @floatFromInt(height);
    ctx.window_has_resized = true;
}

fn callback_cursor_position(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    ctx.mouse_x = @floatCast(x);
    ctx.mouse_y = @floatCast(y);
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
    c.glfwSwapInterval(1);
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
    var shader_texture = try Shader.init(.Circle, shader_vertex_source, shader_fragment_texture_source);
    defer shader_texture.deinit();

    const color_bg = Color.gray(25, 255);

    // setup framebuffer and texture for drawing background
    var bg_framebuffer = try Framebuffer.init();
    bg_framebuffer.bind();
    var bg_texture = Texture.init(ctx.window_width, ctx.window_height, .T0);
    bg_texture.bind();
    bg_framebuffer.texture_attach(bg_texture, .A0);
    try bg_framebuffer.status_check();

    ctx.renderer.clear(color_bg);
    bg_framebuffer.bind_zero();

    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        ctx.time_update();
        ctx.renderer.clear(color_bg);
        // TODO: what happens if a new texture gets bound to the texture.unit before the
        // framebuffer is rebound?

        // render background to a texture
        bg_framebuffer.bind();
        ctx.renderer.blend_enable_alpha();
        if (ctx.window_has_resized) {
            try bg_texture.reset(ctx.window_width, ctx.window_height);
            ctx.renderer.clear(color_bg);
        }

        try ctx.renderer.begin(shader_circle);
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try ctx.renderer.end();
        try ctx.renderer.begin(shader_default);
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try ctx.renderer.end();
        bg_framebuffer.bind_zero();

        // render background texture to framebuffer
        try ctx.renderer.begin(shader_texture);
        try shader_texture.u_texture_set(0);
        try ctx.renderer.draw_rect(0, 0, ctx.window_width, ctx.window_height, Color{});
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
