const std = @import("std");

pub fn hysteresis(gpa: std.mem.Allocator, in: []u8, w: usize) ![]f32 {
    const out = try gpa.alloc(f32, in.len);
    @memset(out, 0);

    var q = try std.Deque(usize).initCapacity(gpa, in.len);
    defer q.deinit(gpa);
    for (in, 0..) |label, i| {
        if (label == 2) {
            try q.pushBack(gpa, i);
            out[i] = 1;
        }
    }

    while (q.popFront()) |i| {
        const row = i / w;
        const col = i % w;

        // TODO: handle 1pxl border
        if (row == 0 or col == 0) {
            continue;
        }

        var rr: i32 = -1;
        var cc: i32 = -1;
        while (rr <= 1) : (rr += 1) {
            while (cc <= 1) : (cc += 1) {
                if (rr == 0 and cc == 0) {
                    continue;
                }

                const nr: i32 = @as(i32, @intCast(row)) + rr;
                const nc: i32 = @as(i32, @intCast(col)) + cc;
                const ni: usize = @as(usize, @intCast(nr)) * w + @as(usize, @intCast(nc));

                if (out[ni] == 0 and in[ni] == 1) {
                    out[ni] = 1;
                    try q.pushBack(gpa, ni);
                }
            }
        }
    }

    return out;
}
