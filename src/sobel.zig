const std = @import("std");

pub const Gradients = struct { mag: []f32, dir: []f32 };

pub fn sobel(gpa: std.mem.Allocator, in: []f32, w: usize, h: usize) !Gradients {
    const mag = try gpa.alloc(f32, in.len);
    const dir = try gpa.alloc(f32, in.len);

    const kx: [9]f32 = .{ -1, 0, 1, -2, 0, 2, -1, 0, 1 };
    const ky: [9]f32 = .{ -1, -2, -1, 0, 0, 0, 1, 2, 1 };

    const gx = try convolve(gpa, in, w, h, &kx);
    const gy = try convolve(gpa, in, w, h, &ky);

    for (0..h) |row| {
        const row_base = row * w;
        for (0..w) |col| {
            const i = row_base + col;
            mag[i] = std.math.sqrt((gx[i] * gx[i]) + (gy[i] * gy[i]));
            dir[i] = std.math.atan2(gy[i], gx[i]);
        }
    }

    return .{ .mag = mag, .dir = dir };
}

fn convolve(gpa: std.mem.Allocator, in: []f32, w: usize, h: usize, k: *const [9]f32) ![]f32 {
    const out = try gpa.alloc(f32, in.len);

    // for each pixel of the input image
    var row: i32 = 0;
    while (row < h) : (row += 1) {
        var col: i32 = 0;
        while (col < w) : (col += 1) {
            var acc: f32 = 0;

            // for each kernel weight
            for ([_]i32{ -1, 0, 1 }) |krow| {
                const in_row = std.math.clamp(row + krow, 0, h - 1) * w;
                const k_row = (krow + 1) * 3;
                for ([_]i32{ -1, 0, 1 }) |kcol| {
                    const clamped_col = std.math.clamp(col + kcol, 0, w - 1);
                    const ini: usize = @intCast(in_row + clamped_col);
                    const ki: usize = @intCast(k_row + (kcol + 1));
                    acc = acc + k[ki] * in[ini];
                }
            }

            const ww: i32 = @intCast(w);
            const outi: usize = @intCast(row * ww + col);
            out[outi] = acc;
        }
    }

    return out;
}
