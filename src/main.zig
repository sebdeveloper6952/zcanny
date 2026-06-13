const std = @import("std");
const zigimg = @import("zigimg");
const img = @import("img.zig");
const gaussian_smooth = @import("gaussian_smoothing.zig").gaussian_smooth;
const sobel = @import("sobel.zig").sobel;
const nms = @import("nms.zig");
const dt = @import("double_threshold.zig");
const hysteresis = @import("hysteresis.zig").hysteresis;

const Io = std.Io;

const Config = struct {
    input_path: []const u8 = "dev.png",
    output_path: []const u8 = "output/",
    sigma: f32 = 1.4,

    dt_p: f32 = 0.85,
    dt_bins: usize = 1024,
    dt_ratio: f32 = 3,

    fn init(args: []const [:0]const u8) !Config {
        _ = args;

        return .{};
    }
};

pub fn main(init: std.process.Init) !void {
    // TODO: optimize allocator
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    const allocator = arena.allocator();

    // TODO: cli flags
    const args = try init.minimal.args.toSlice(arena.allocator());
    const config = try Config.init(args);

    // create the output directory
    try std.Io.Dir.cwd().createDirPath(init.io, config.output_path);

    // open input image, for now hardcoded
    var file = try std.Io.Dir.cwd().openFile(init.io, config.input_path, .{});
    defer file.close(init.io);

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFile(allocator, init.io, file, read_buffer[0..]);

    // image to grayscale8
    try image.convert(allocator, .grayscale8);

    // we build a f32 pixel data, this is what will start the pipeline
    const original = try allocator.alloc(f32, image.width * image.height);
    for (original, image.pixels.grayscale8) |*out, px| {
        out.* = @as(f32, @floatFromInt(px.value)) / 255.0;
    }

    // ########################### Canny Pipeline ##############################
    // Stage 1: Gaussian Blur
    const smoothed = try gaussian_smooth(allocator, original, image.width, image.height, config.sigma);
    try img.write_img(allocator, init.io, "gaussian_blur.png", smoothed, image.width, image.height);

    // Stage 2: Sobel Gradients
    const gradients = try sobel(allocator, smoothed, image.width, image.height);
    try img.write_img(allocator, init.io, "mag.png", gradients.mag, image.width, image.height);

    // Stage 3: Non maximum suppression
    const thinned_mag = try nms.quantized_nms(allocator, gradients.mag, gradients.dir, image.width, image.height);
    try img.write_img(allocator, init.io, "thinned_mag.png", thinned_mag, image.width, image.height);

    // Stage 4: Double thresholding
    const labels = try dt.percentile(allocator, thinned_mag, config.dt_bins, config.dt_p, config.dt_ratio);

    // Stage 5: Hysteresis
    const binary_map = try hysteresis(allocator, labels, image.width);
    try img.write_img(allocator, init.io, "canny.png", binary_map, image.width, image.height);
}
