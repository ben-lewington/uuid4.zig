// Fast allocation-free v4 UUIDs.
// adapted from https://github.com/dmgk/zig-uuid
const Uuid = @This();

const std = @import("std");
const crypto = std.crypto;
const fmt = std.fmt;
const testing = std.testing;

bytes: [16]u8,

// Convenience function to return a new v4 Uuid.
pub fn newV4() Uuid {
    var uuid = Uuid{ .bytes = undefined };

    crypto.random.bytes(&uuid.bytes);
    // Version 4
    uuid.bytes[6] = (uuid.bytes[6] & 0x0f) | 0x40;
    // Variant 1
    uuid.bytes[8] = (uuid.bytes[8] & 0x3f) | 0x80;
    return uuid;
}

fn asOwnedBytes(self: Uuid) [36]u8 {
    var buf: [36]u8 = undefined;
    inline for (constants.delimiter_positions) |i| {
        buf[i] = '-';
    }
    inline for (constants.encoded_position, 0..) |i, j| {
        buf[i + 0] = constants.hex_digits[self.bytes[j] >> 4];
        buf[i + 1] = constants.hex_digits[self.bytes[j] & 0x0f];
    }
    return buf;
}

pub fn format(self: Uuid, comptime layout: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
    _ = options; // currently unused

    if (layout.len != 0 and layout[0] != 's')
        @compileError("Unsupported format specifier for Uuid type: '" ++ layout ++ "'.");

    try fmt.format(writer, "{s}", .{self.asOwnedBytes()});
}

pub fn parse(buf: []const u8) !Uuid {
    var uuid = Uuid{ .bytes = undefined };

    if (buf.len != 36) return error.InvalidUUID;

    var valid = true;

    inline for (constants.delimiter_positions) |pos| {
        if (buf[pos] != '-') valid = false;
    }

    if (!valid) return error.InvalidUUID;

    inline for (constants.encoded_position, 0..) |i, j| {
        const hi = constants.hex_to_nibble_codec[buf[i + 0]];
        const lo = constants.hex_to_nibble_codec[buf[i + 1]];
        if (hi == 0xff or lo == 0xff) {
            return error.InvalidUUID;
        }
        uuid.bytes[j] = hi << 4 | lo;
    }

    return uuid;
}

const constants = struct {
    const delimiter_positions = &.{ 8, 13, 18, 23 };

    // Indices in the Uuid string representation for each byte.
    const encoded_position = [16]u8{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 };

    // Hex digits
    const hex_digits = "0123456789abcdef";

    // Hex to nibble mapping.
    const hex_to_nibble_codec = [256]u8{
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    };
};

test "parse and format" {
    const uuids = [_][]const u8{
        "d0cd8041-0504-40cb-ac8e-d05960d205ec",
        "3df6f0e4-f9b1-4e34-ad70-33206069b995",
        "f982cf56-c4ab-4229-b23c-d17377d000be",
        "6b9f53be-cf46-40e8-8627-6b60dc33def8",
        "c282ec76-ac18-4d4a-8a29-3b94f5c74813",
        "00000000-0000-0000-0000-000000000000",
    };

    for (uuids) |uuid| {
        try testing.expectFmt(uuid, "{}", .{try Uuid.parse(uuid)});
    }
}

test "invalid Uuid" {
    const uuids = [_][]const u8{
        "3df6f0e4-f9b1-4e34-ad70-33206069b99", // too short
        "3df6f0e4-f9b1-4e34-ad70-33206069b9912", // too long
        "3df6f0e4-f9b1-4e34-ad70_33206069b9912", // missing or invalid group separator
        "zdf6f0e4-f9b1-4e34-ad70-33206069b995", // invalid character
    };

    for (uuids) |uuid| {
        try testing.expectError(error.InvalidUUID, Uuid.parse(uuid));
    }
}

test "check AsBytes works" {
    const uuid1 = Uuid.newV4();

    const string1 = uuid1.asOwnedBytes();
    const string2 = uuid1.asOwnedBytes();

    try testing.expectEqual(string1, string2);
}
