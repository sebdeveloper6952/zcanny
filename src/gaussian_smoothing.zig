const std = @import("std");

pub fn gaussian_smooth(gpa: std.mem.Allocator, in: []f32, w: usize, h: usize, sigma: f32) ![]f32 {
    const k = try gaussian_kernel_1d(gpa, sigma);
    defer gpa.free(k);

    const tmp = try gpa.alloc(f32, in.len);
    const smoothed = try gpa.alloc(f32, in.len);

    const radius: usize = @intFromFloat(std.math.ceil(3 * sigma));
    blur_h(in, tmp, w, h, k, radius);
    blur_v(tmp, smoothed, w, h, k, radius);

    return smoothed;
}

fn gaussian_kernel_1d(gpa: std.mem.Allocator, sigma: f32) ![]f32 {
    const radius: usize = @intFromFloat(std.math.ceil(3 * sigma));
    const kernel = try gpa.alloc(f32, radius);

    const s2 = 2 * sigma * sigma;
    for (0..radius) |i| {
        const ii: f32 = @floatFromInt(i * i);
        kernel[i] = std.math.exp(-(ii) / s2);
    }

    var total_weight: f32 = kernel[0];
    for (1..radius) |i| {
        total_weight = total_weight + 2 * kernel[i];
    }

    for (0..radius) |i| {
        kernel[i] = kernel[i] / total_weight;
    }

    std.debug.print("kernel radius: {d:.2}\n", .{radius});
    for (kernel) |kv| {
        std.debug.print("{d:.2},", .{kv});
    }
    std.debug.print("\n", .{});

    return kernel;
}

fn blur_h(in: []f32, out: []f32, w: usize, h: usize, kernel: []f32, radius: usize) void {
    for (0..h) |row| {
        const base = row * w;
        for (0..w) |col| {
            var acc: f32 = kernel[0] * in[base + col];
            for (1..radius) |j| {
                const cl = std.math.sub(usize, col, j) catch 0;
                const cr = @min(col + j, w - 1);
                acc = acc + kernel[j] * (in[base + cl] + in[base + cr]);
            }
            out[base + col] = acc;
        }
    }
}

fn blur_v(in: []f32, out: []f32, w: usize, h: usize, kernel: []f32, radius: usize) void {
    for (0..w) |col| {
        for (0..h) |row| {
            const base = row * w;
            var acc: f32 = kernel[0] * in[base + col];
            for (1..radius) |j| {
                const cl = std.math.sub(usize, col, j) catch 0;
                const cr = @min(col + j, w - 1);
                acc = acc + kernel[j] * (in[base + cl] + in[base + cr]);
            }
            out[base + col] = acc;
        }
    }
}
