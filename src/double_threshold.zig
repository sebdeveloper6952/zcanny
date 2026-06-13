const std = @import("std");

pub fn percentile(gpa: std.mem.Allocator, in: []f32, num_bins: usize, p: f32, ratio: f32) ![]u8 {
    const out = try gpa.alloc(u8, in.len);

    var max_mag: f32 = 0;
    for (in) |mag| {
        if (mag > max_mag) {
            max_mag = mag;
        }
    }

    const hist = try gpa.alloc(usize, num_bins);
    // NOTE: valuable lesson here, without this, mem is undefined
    @memset(hist, 0);
    const bins: f32 = @floatFromInt(num_bins);
    var count: usize = 0;
    for (in) |mag| {
        if (mag > 0) {
            const bin: usize = @intFromFloat(@min(std.math.floor((mag / max_mag) * bins), bins - 1));
            hist[bin] += 1;
            count += 1;
        }
    }

    const target_count: usize = @intFromFloat(std.math.floor(p * @as(f32, @floatFromInt(count))));
    var acc: usize = 0;
    var bin_index: usize = 0;
    for (hist) |c| {
        acc += c;
        if (acc > target_count) {
            break;
        }
        bin_index += 1;
    }

    const hi: f32 = @as(f32, @floatFromInt((bin_index + 1))) / bins * max_mag;
    const lo: f32 = hi / ratio;

    for (in, 0..) |mag, i| {
        if (mag >= hi) {
            out[i] = 2;
        } else if (mag >= lo) {
            out[i] = 1;
        } else {
            out[i] = 0;
        }
    }

    return out;
}
