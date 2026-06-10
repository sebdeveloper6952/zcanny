const std = @import("std");
const zigimg = @import("zigimg");

pub fn write_img(gpa: std.mem.Allocator, io: std.Io, path: []const u8, pixels: []f32, w: usize, h: usize) !void {
    var out_image = try zigimg.Image.create(gpa, w, h, .grayscale8);
    defer out_image.deinit(gpa);
    for (out_image.pixels.grayscale8, pixels) |*px, v| {
        const c = std.math.clamp(v, 0.0, 1.0);
        px.* = .{ .value = @intFromFloat(@round(c * 255.0)) };
    }

    const write_path = try std.fmt.allocPrint(gpa, "{s}{s}", .{ "output/", path });
    defer gpa.free(write_path);

    var write_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    try out_image.writeToFilePath(gpa, io, write_path, write_buffer[0..], .{ .png = .{} });
}
