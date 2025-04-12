const Color = @This();

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

pub const White = Color{
    .r = 255,
    .g = 255,
    .b = 255,
};

pub const Black = Color{};
