const std = @import("std");
pub usingnamespace @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
    // @cDefine("STB_IMAGE_IMPLEMENTATION", {});
    @cInclude("stb_image.h");
});
