load("//internal/starlark:util.bzl", "run_starlark_executor")

def _terraform_locals_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + "_locals.tf.json")

    run_starlark_executor(
        ctx,
        output,
        ctx.file.src,
        ctx.files.deps,
        ctx.executable._starlark_executor,
        """
# Create local variable definitions for .tf.json file
def wrap_locals(x):
    assert_type(x, "dict")

    return { "locals": x }
        """,
        "encode_indent(wrap_locals(main()))",
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
