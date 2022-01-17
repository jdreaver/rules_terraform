def run_starlark_executor(ctx, output, src, deps, executor, lib, expr):
    ctx.actions.run(
        outputs = [output],
        inputs = [src] + deps,
        executable = executor,
        arguments = [
            "-input", src.path,
            "-output", output.path,
            "-expr", expr,
            "-lib", lib,
        ],
    )
