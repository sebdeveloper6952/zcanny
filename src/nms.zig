const std = @import("std");

pub fn quantized_nms(gpa: std.mem.Allocator, mag: []f32, dir: []f32, w: usize, h: usize) ![]f32 {
    const out = try gpa.alloc(f32, mag.len);

    for (1..h - 1) |row| {
        const base = row * w;
        for (1..w - 1) |col| {
            const index = base + col;

            // we don't check 0 magnitude vectors
            var degrees = std.math.radiansToDegrees(dir[index]);
            if (degrees < 0) degrees += 180.0;

            var off: usize = 0;
            if (degrees < 22.5 or degrees >= 157.5) {
                off = 1;
            } else if (degrees < 67.5) {
                off = w + 1;
            } else if (degrees < 112.5) {
                off = w;
            } else {
                off = w - 1;
            }

            const m = mag[index];
            if (m >= mag[index - off] and m >= mag[index + off]) {
                out[index] = m;
            }
        }
    }

    return out;
}

// TODO: implement
// pub fn interpolated_nms(gpa: std.mem.Allocator, mag: []f32, dir: []f32, w: usize, h: usize) ![]f32 {
//
// }
