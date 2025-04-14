const c = @import("./c.zig");
const Texture = @import("./Texture.zig");

const ErrorFramebuffer = error{
    NotBound,
    FramebufferNotComplete,
};

const Framebuffer = @This();

id: c_uint,

pub fn init() ErrorFramebuffer!Framebuffer {
    var id: c_uint = undefined;
    c.glGenFramebuffers(1, &id);
    if (c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
        return ErrorFramebuffer.FramebufferNotComplete;
    }
    return Framebuffer{
        .id = id,
    };
}

pub fn deinit(self: *Framebuffer) void {
    c.glDeleteFramebuffers(1, self.id);
}

/// bind Framebuffer.id to GL_FRAMEBUFFER
pub fn bind(self: *Framebuffer) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.id);
}

/// bind GL_FRAMEBUFFER to 0
pub fn bind_zero(_: *Framebuffer) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
}

/// set the GL_FRAMEBUFFER id
pub fn bind_id_set(id: c_uint) void {
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, id);
}

/// get the id bound to GL_FRAMEBUFFER
pub fn bind_id_get() c_int {
    var result: c_int = undefined;
    c.glGetIntegerv(c.GL_FRAMEBUFFER_BINDING, &result);
    return result;
}

/// true if Framebuffer.id is currently bound to GL_FRAMEBUFFER
pub fn bind_check(self: *Framebuffer) bool {
    return Framebuffer.bind_id_get() == self.id;
}

pub fn status_check(self: *Framebuffer) ErrorFramebuffer!void {
    if (!self.bind_check()) {
        return ErrorFramebuffer.NotBound;
    }
    if (c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE) {
        return ErrorFramebuffer.FramebufferNotComplete;
    }
}

pub fn texture_attach(_: *Framebuffer, texture: Texture, attatchment: Attachment) void {
    c.glFramebufferTexture2D(c.GL_FRAMEBUFFER, @intFromEnum(attatchment), c.GL_TEXTURE_2D, texture.id, 0);
}

const Attachment = enum(c_uint) {
    A0 = c.GL_COLOR_ATTACHMENT0,
    A1 = c.GL_COLOR_ATTACHMENT1,
    A2 = c.GL_COLOR_ATTACHMENT2,
    A3 = c.GL_COLOR_ATTACHMENT4,
    A5 = c.GL_COLOR_ATTACHMENT5,
    A6 = c.GL_COLOR_ATTACHMENT6,
    A7 = c.GL_COLOR_ATTACHMENT7,
    A8 = c.GL_COLOR_ATTACHMENT8,
};
