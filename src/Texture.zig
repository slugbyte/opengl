const c = @import("./c.zig");

const ErrorTexture = error{
    ResizeWithMipmapNotPossible,
};

const Texture = @This();

id: c_uint,
width: f32,
height: f32,
unit: Unit,
has_mipmap: bool = false,

pub fn init(width: f32, height: f32, unit: Unit) Texture {
    var id: c_uint = undefined;
    c.glGenTextures(1, &id);
    c.glActiveTexture(@intFromEnum(unit));
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, @intFromFloat(width), @intFromFloat(height), 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    return Texture{
        .id = id,
        .width = width,
        .height = height,
        .unit = unit,
    };
}

pub fn deinit(self: *Texture) void {
    c.glDeleteTextures(1, &self.id);
}

/// bind Texture to GL_TEXTURE_2D
pub fn bind(self: *Texture) void {
    c.glActiveTexture(@intFromEnum(self.unit));
    c.glBindTexture(c.GL_TEXTURE_2D, self.id);
}

/// bind Texture.unit's GL_TEXTURE_2D to 0
pub fn bind_zero(self: *Texture) void {
    c.glActiveTexture(self.unit);
    c.glBindTexture(c.GL_TEXTURE_2D, 0);
}

/// true if Texture.id is currently bound to GL_TEXTURE_2D
pub fn bind_check(self: *Texture) bool {
    return Texture.get_bind_id() == self.id;
}

/// get the id bound to GL_TEXTURE_2D
pub fn bind_id_get() c_uint {
    var id: c_uint = undefined;
    c.glGetIntegerv(c.GL_TEXTURE_BINDING_2D, &id);
    return id;
}

pub fn GL_MAX_TEXTURE_IMAGE_UNITS() c_int() {
    const result: c_int = undefined;
    c.glGetIntegerv(c.GL_MAX_TEXTURE_IMAGE_UNITS, &result);
    return result;
}

/// reset the Texture size (will error if it has_mipmap is true)
pub fn reset(self: *Texture, width: f32, height: f32) ErrorTexture!void {
    if (self.has_mipmap) {
        return ErrorTexture.ResizeWithMipmapNotPossible;
    }
    self.width = width;
    self.height = height;
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, @intFromFloat(width), @intFromFloat(height), 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, null);
}

pub const Unit = enum(c_uint) {
    T0 = c.GL_TEXTURE0,
    T1 = c.GL_TEXTURE1,
    T2 = c.GL_TEXTURE2,
    T3 = c.GL_TEXTURE3,
    T4 = c.GL_TEXTURE4,
    T5 = c.GL_TEXTURE5,
    T6 = c.GL_TEXTURE6,
    T7 = c.GL_TEXTURE7,
    T8 = c.GL_TEXTURE8,
    T9 = c.GL_TEXTURE9,
    T10 = c.GL_TEXTURE10,
    T11 = c.GL_TEXTURE11,
    T12 = c.GL_TEXTURE12,
    T13 = c.GL_TEXTURE13,
    T14 = c.GL_TEXTURE14,
    T15 = c.GL_TEXTURE15,
    T16 = c.GL_TEXTURE16,
    T17 = c.GL_TEXTURE17,
    T18 = c.GL_TEXTURE18,
    T19 = c.GL_TEXTURE19,
    T20 = c.GL_TEXTURE20,
    T21 = c.GL_TEXTURE21,
    T22 = c.GL_TEXTURE22,
    T23 = c.GL_TEXTURE23,
    T24 = c.GL_TEXTURE24,
    T25 = c.GL_TEXTURE25,

    pub fn toUniformLocation(self: Unit) c_int {
        return switch (self) {
            .T0 => 0,
            .T1 => 1,
            .T2 => 2,
            .T3 => 3,
            .T4 => 4,
            .T5 => 5,
            .T6 => 6,
            .T7 => 7,
            .T8 => 8,
            .T9 => 9,
            .T10 => 10,
            .T11 => 11,
            .T12 => 12,
            .T13 => 13,
            .T14 => 14,
            .T15 => 15,
            .T16 => 16,
            .T17 => 17,
            .T18 => 18,
            .T19 => 19,
            .T20 => 20,
            .T21 => 21,
            .T22 => 22,
            .T23 => 23,
            .T24 => 24,
            .T25 => 25,
        };
    }
};
