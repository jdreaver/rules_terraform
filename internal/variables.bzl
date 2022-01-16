def _terraform_locals_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + "_locals.tf.json")

    ctx.actions.run(
        outputs = [output],
        inputs = [ctx.file.src] + ctx.files.deps,
        executable = ctx.executable._starlark_executor,
        arguments = [
            "-input", ctx.file.src.path,
            "-output", output.path,
            "-expr", "encode_indent(wrap_locals(main()))",
        ],
    )

    return [DefaultInfo(files = depset([output]))]

terraform_locals = rule(
    implementation = _terraform_locals_impl,
    doc = "Creates a .tf.json file defining local variables from a Starlark dict",
    attrs = {
        "src": attr.label(
            doc = "Source Starlark file to execute",
            mandatory = True,
            allow_single_file = True,
        ),
        "deps": attr.label_list(
            doc = "Files needed to execute Starlark",
        ),
        "_starlark_executor": attr.label(
            default = Label("//internal/starlark"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
