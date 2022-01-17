load("//internal/starlark:util.bzl", "run_starlark_executor")

TerraformBackendInfo = provider(
    "Provider for terraform_backend rule.",
    fields = {
        "src": "Source starlark file",
        "deps": "Dependencies of starlark file",
    })

def _terraform_backend_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + "_backend.tf.json")

    run_starlark_executor(
        ctx,
        output,
        ctx.file.src,
        ctx.files.deps,
        ctx.executable._starlark_executor,
        """
# Create a .tf.json backend block
def wrap_backend(backend_type, config):
    assert_type(backend_type, "string")
    assert_type(config, "dict")

    return {
        "terraform": {
            "backend": {
                backend_type: config
            }
        }
    }
        """,
        "encode_indent(wrap_backend(**main()))",
    )


    return [
        DefaultInfo(files = depset([output])),
        TerraformBackendInfo(
            src = ctx.file.src,
            deps = ctx.files.deps,
        )
    ]

terraform_backend = rule(
    implementation = _terraform_backend_impl,
    doc = """Creates a .tf.json file defining terraform_backend

    You can't use variables in Terraform backend blocks
    (https://github.com/hashicorp/terraform/issues/13022), so it is important
    for us to generate them if we want to use external variables. Also, this
    rule can be used as an input to the `terraform_remote_state` rule to
    generate a `terraform_remote_state` block for another root.
    """,
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

def _terraform_remote_state_impl(ctx):
    backend = ctx.attr.backend[TerraformBackendInfo]
    output = ctx.actions.declare_file(ctx.label.name + "_remote_state.tf.json")

    run_starlark_executor(
        ctx,
        output,
        backend.src,
        backend.deps,
        ctx.executable._starlark_executor,
        """
# Create a .tf.json terraform_remote_state block
def wrap_backend_remote_state(backend_type, config, variable_name):
    assert_type(backend_type, "string")
    assert_type(config, "dict")
    assert_type(variable_name, "string")

    return {
        "data": {
            "terraform_remote_state": {
                variable_name: {
                    "backend": backend_type,
                    "config": config,
                },
            }
        }
    }
        """,
        "encode_indent(wrap_backend_remote_state(variable_name = '{}', **main()))".format(ctx.attr.variable_name),
    )


    return [DefaultInfo(files = depset([output]))]

terraform_remote_state = rule(
    implementation = _terraform_remote_state_impl,
    doc = "Creates a .tf.json file defining terraform_remote_state",
    attrs = {
        "backend": attr.label(
            providers = [TerraformBackendInfo],
            doc = "Label for terraform_backend to reference.",
        ),
        "variable_name": attr.string(
            mandatory = True,
            doc = "Terraform variable name to use for this remote state block",
        ),
        "_starlark_executor": attr.label(
            default = Label("//internal/starlark"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
