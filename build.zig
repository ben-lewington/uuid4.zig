const std = @import("std");

pub fn addUuidImport(
    b: *std.Build,
    obj: *std.Build.Step.Compile,
    opts: struct {
        import_as: []const u8 = "Uuid",
        target: ?std.Build.ResolvedTarget = null,
        optimize: ?std.builtin.OptimizeMode = null,
    },
) !void {
    const lib = b.addSharedLibrary(.{
        .name = "Uuid",
        .target = opts.target orelse b.standardTargetOptions(.{}),
        .optimize = opts.optimize orelse b.standardOptimizeOption(.{}),
    });
    obj.root_module.addImport(opts.import_as, &lib.root_module);
}
