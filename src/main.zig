//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const ctx = @import("./context.zig");

const gl = @import("./gl.zig");
const Shader = @import("./Shader.zig");
const Framebuffer = @import("./Framebuffer.zig");
const Texture = @import("./Texture.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");
const Button = @import("./Button.zig");
const Rect = @import("./Rect.zig");
const gui = @import("gui.zig");

var button_state: i32 = 0;
fn button_callback() void {
    ctx.inspect("boom {d}", .{button_state});
    button_state += 1;
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

    const window = c.glfwCreateWindow(800, 600, "DEMO", null, null);
    if (window == null) {
        @panic("glfw failed to create window");
    }
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    try ctx.init();
    try gl.init(allocator);
    defer gl.deinit();

    ctx.glfw_callback_framebuffer_resize(window, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, &ctx.glfw_callback_framebuffer_resize);
    _ = c.glfwSetCursorPosCallback(window, &ctx.glfw_callback_cursor_position);
    _ = c.glfwSetMouseButtonCallback(window, &ctx.glfw_callback_mouse_button);

    var dot_list = std.ArrayList(Dot).init(allocator);
    for (1..100) |_| {
        try dot_list.append(Dot.init());
    }
    const color_bg = Color.gray(25, 255);

    // setup framebuffer and texture for drawing background
    var bg_texture = Texture.init(ctx.window_width, ctx.window_height, .T3);
    defer bg_texture.deinit();
    var bg_framebuffer = try Framebuffer.init();
    bg_framebuffer.bind();
    bg_framebuffer.texture_attach(bg_texture, .A0);
    try bg_framebuffer.status_check();
    gl.clear(color_bg);
    bg_framebuffer.bind_zero();

    // setup button
    var button = Button.init(100, 100, 100, 50);
    button.on_click(&button_callback);

    var slider_value: f32 = 0;
    while (c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwPollEvents();
        ctx.update_begin();

        gl.clear(color_bg);
        // TODO: what happens if a new texture gets bound to the texture.unit before the
        // framebuffer is rebound?

        // render background to a texture
        bg_framebuffer.bind();
        if (ctx.window_has_resized) {
            try bg_texture.reset(ctx.window_width, ctx.window_height);
            gl.clear(color_bg);
        }

        try gl.shader_program_set(.{ .Circle = {} });
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try gl.batch.flush();

        try gl.shader_program_set(.{ .Default = {} });
        for (dot_list.items) |*dot_item| {
            dot_item.update();
            try dot_item.render();
        }
        try gl.batch.flush();
        bg_framebuffer.bind_zero();

        bg_texture.bind();
        try gl.shader_program_set(.{ .Texture = bg_texture });
        try gl.batch.draw_rect(0, 0, ctx.window_width, ctx.window_height, Color{});
        try gl.batch.flush();

        // pallet
        const pallet_x = @divFloor(ctx.window_width, 2) - 125;
        const pallet_y = @divFloor(ctx.window_height, 6) - 125;
        try gl.shader_program_set(.{ .Default = {} });
        try gl.batch.draw_rect(pallet_x, pallet_y, 250, 250, Color.Black);
        try gl.batch.draw_rect_color_interploate(pallet_x + 2, pallet_y + 2, 246, 246, Color.White, Color{ .r = 255 }, Color{}, Color.Black);
        try gl.batch.draw_rect(pallet_x, pallet_y + 255, 250, 50, Color{});
        try gl.batch.flush();

        try button.render();

        if (try gui.button(@src(), Rect.init(500, 500, 50, 20))) {
            std.debug.print("booooom im_button!\n", .{});
            _ = c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        }

        slider_value = try gui.slider(@src(), Rect.init(100, 100, 50, 200), slider_value);
        // _ = slider_value;
        std.debug.print("slider_value: {d}\n", .{slider_value});

        ctx.update_end();
        ctx.debug_hud_print();
        c.glfwSwapBuffers(window);
    }
}
