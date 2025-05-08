const std = @import("std");

const Color = @This();

r: u8 = 0,
g: u8 = 0,
b: u8 = 0,
a: u8 = 255,

pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
    return Color{ .r = r, .g = g, .b = b, .a = a };
}

pub fn init_hexcode(comptime hexcode: []const u8, alpha: u8) Color {
    if (hexcode.len != 7) {
        @compileError("init_hexcode should be 7 digets #rrggbb");
    }
    const r: u8 = std.fmt.parseInt(u8, hexcode[1..3], 16) catch {
        @compileError("init_hexcode r not parsable");
    };
    const g: u8 = std.fmt.parseInt(u8, hexcode[3..5], 16) catch {
        @compileError("init_hexcode g not parsable");
    };
    const b: u8 = std.fmt.parseInt(u8, hexcode[5..7], 16) catch {
        @compileError("init_hexcode b not parsable");
    };
    return Color{
        .r = r,
        .g = g,
        .b = b,
        .a = alpha,
    };
}

pub const White = Color{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

pub const Black = Color{};

pub const Clear = Color.init(0, 0, 0, 0);

pub const Red = Color.init_hexcode("#f21f38", 255);
pub const Green = Color.init_hexcode("#06e227", 255);
pub const Blue = Color.init_hexcode("#1183fc", 255);
pub const Yellow = Color.init_hexcode("#dae238", 255);
pub const Orange = Color.init_hexcode("#e28838", 255);
pub const Pink = Color.init_hexcode("#fc377c", 255);

pub fn gray(value: u8, alpha: u8) Color {
    return Color{
        .r = value,
        .g = value,
        .b = value,
        .a = alpha,
    };
}

pub inline fn gl_r(self: *const Color) f32 {
    return @as(f32, @floatFromInt(self.r)) / 255.0;
}
pub inline fn gl_g(self: *const Color) f32 {
    return @as(f32, @floatFromInt(self.g)) / 255.0;
}
pub inline fn gl_b(self: *const Color) f32 {
    return @as(f32, @floatFromInt(self.b)) / 255.0;
}
pub inline fn gl_a(self: *const Color) f32 {
    return @as(f32, @floatFromInt(self.a)) / 255.0;
}

pub inline fn gl_vertex(self: *const Color) [4]f32 {
    return .{
        self.gl_r(),
        self.gl_g(),
        self.gl_b(),
        self.gl_a(),
    };
}

pub fn format(self: Color, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;

    try writer.print("Color({d}, {d}, {d}, {d})", .{ self.r, self.g, self.b, self.a });
}
