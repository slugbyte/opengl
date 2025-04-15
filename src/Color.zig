const Color = @This();

r: u8 = 0,
g: u8 = 0,
b: u8 = 0,
a: u8 = 255,

pub const White = Color{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

pub const Black = Color{};

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
