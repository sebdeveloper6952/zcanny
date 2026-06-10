const std = @import("std");
const zigimg = @import("zigimg");
const gaussian_smooth = @import("gaussian_smoothing.zig").gaussian_smooth;
const img = @import("img.zig");

const Io = std.Io;

const Flags = struct {
    input_path: []u8 = "dev.png",
    output_path: []u8 = "output/",
    sigma: f32,
};

pub fn main(init: std.process.Init) !void {
    // TODO: optimize allocator
    var allocator = init.gpa;

    // TODO: cli flags
    // const flags = Flags{};
    try std.Io.Dir.cwd().createDirPath(init.io, "output");

    // open input image, for now hardcoded
    var file = try std.Io.Dir.cwd().openFile(init.io, "dev.png", .{});
    defer file.close(init.io);

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFile(allocator, init.io, file, read_buffer[0..]);
    defer image.deinit(allocator);
    std.debug.print("input dimensions: {d}x{d}\n", .{ image.height, image.width });

    // image to grayscale8
    try image.convert(allocator, .grayscale8);

    // we build a f32 pixel data, this is what will start the pipeline
    const original = try allocator.alloc(f32, image.width * image.height);
    defer allocator.free(original);
    for (original, image.pixels.grayscale8) |*out, px| {
        out.* = @as(f32, @floatFromInt(px.value)) / 255.0;
    }

    // ########################### Canny Pipeline ##############################
    // Stage 1: Gaussian Blur
    const smoothed = try gaussian_smooth(allocator, original, image.width, image.height, 1.4);
    defer allocator.free(smoothed);
    try img.write_img(allocator, init.io, "gaussian_blur.png", smoothed, image.width, image.height);

    // Stage 2: Sobel Gradients
}
