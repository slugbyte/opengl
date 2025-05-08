const std = @import("std");
pub const fnv = std.hash.Fnv1a_32;

pub fn src(source: std.builtin.SourceLocation, item_index: ?usize) u32 {
    const index = item_index orelse 0;
    var hash = fnv.init();
    hash.update(std.mem.asBytes(&source.file.ptr));
    hash.update(std.mem.asBytes(&source.module.ptr));
    hash.update(std.mem.asBytes(&source.line));
    hash.update(std.mem.asBytes(&source.column));
    hash.update(std.mem.asBytes(&source.column));
    hash.update(std.mem.asBytes(&index));
    return hash.final();
}
