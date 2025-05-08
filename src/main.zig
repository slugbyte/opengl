// ! By convention, main.zig is where your main function lives in the case that
// ! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const c = @import("./c.zig");
const debug = @import("./debug.zig");
const config = @import("config");
const window = @import("./Window.zig");

const gl = @import("./gl.zig");
const Shader = @import("./Shader.zig");
const Framebuffer = @import("./Framebuffer.zig");
const Texture = @import("./Texture.zig");
const Color = @import("./Color.zig");
const Dot = @import("./Dot.zig");
const Vec = @import("./Vec.zig");
const Size = @import("./Size.zig");
const Rect = @import("./Rect.zig");
const gui = @import("gui.zig");

const IMAGE_BING = @embedFile("./asset/bing.jpg");

var button_state: i32 = 0;

pub fn main() !void {
    std.debug.print("All your pixels are blong to us!\n", .{});

    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    try window.init("DEMO", .{ .color_background = Color.Black });
    defer window.deinit();

    try gl.init(allocator);
    defer gl.deinit();

    // var show_border: bool = false;
    while (window.should_render()) {
        window.frame_begin();
        gui.begin(window.mouse);

        // const menu = try gui.box(Vec.init(0, 0), Size.init(window.size.width * 0.25, window.size.height), .{
        var menu = try gui.box(@src(), .{
            .rect = Rect.from(0, 0, window.size.width, 100),
            .color = Color.Blue,
            .padding = 10,
            .spacing = 10,
            .cursor_direction = .Horizontal,
            .allow_overflow = false,
        });

        _ = try gui.box(@src(), .{
            .rect = menu.next_fill(500),
            .color = Color.Red,
        });

        _ = try gui.box(@src(), .{
            .rect = menu.next_fill(500),
            .color = Color.Orange,
        });

        var green = try gui.box(@src(), .{
            .rect = menu.next_fill(150),
            .color = Color.Green,
            .spacing = 10,
            .padding = 10,
        });

        _ = try gui.box(@src(), .{
            .rect = green.next_fill(50),
            .color = Color.Black,
            .spacing = 10,
            .padding = 10,
        });

        if (try gui.button_rect(@src(), .{
            .rect = green.next_fill(50),
            .color = Color.Red,
        })) {
            std.debug.print("siik\n", .{});
        }

        menu.end();

        // menu.end();

        // stack.end();

        gui.end();
        window.frame_end();
    }

    debug.clear();
    std.debug.print("bye!", .{});
}
