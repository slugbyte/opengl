const c = @import("./c.zig");

const Framebuffer = @This();

const ATTATCHMENT = enum(c_int) {
    A0 = c.GL_COLOR_ATTACHMENT0,
    A1 = c.GL_COLOR_ATTACHMENT1,
    A2 = c.GL_COLOR_ATTACHMENT2,
    A3 = c.GL_COLOR_ATTACHMENT4,
    A5 = c.GL_COLOR_ATTACHMENT5,
    A6 = c.GL_COLOR_ATTACHMENT6,
    A7 = c.GL_COLOR_ATTACHMENT7,
    A8 = c.GL_COLOR_ATTACHMENT8,

    pub fn getLocation(self: *ATTATCHMENT) c_int {
        return switch (self) {
            .A0 => 0,
            .A1 => 1,
            .A2 => 2,
            .A3 => 3,
            .A4 => 4,
            .A5 => 5,
            .A6 => 6,
            .A7 => 7,
            .A8 => 8,
        };
    }
};

id: c_uint,

pub fn init() Framebuffer {
    var id: c_uint = undefined;
    c.glGenFramebuffers(1, &id);
    return Framebuffer{
        .id = id,
    };
}

pub fn bind(self: *Framebuffer) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.id);
}

pub fn bind_attach_color_texture(self: *Framebuffer, attatchment: ATTATCHMENT, texture: c_uint) void {
    self.bind();
    c.glFramebufferTexture2D(c.GL_FRAMEBUFFER, attatchment, c.GL_TEXTURE_2D, texture, 0);
}
