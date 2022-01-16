load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//internal/starlark:util.bzl", "run_starlark_executor")

TerraformBackendInfo = provider(
    "Provider for _terraform_backend_internal rule.",
    fields = {
        "backend_type": "Name of backend, like s3",
        # N.B. This is a JSON string because you can't use arbitrary Starlark
        # values in bazel rules. We can't use a string_dict either because some
        # backend configs have nested dicts.
        "config_json": "JSON string for backend configuration",
        "terraform_json": "Reified Terraform .tf.json file for the config",
    })

def _terraform_backend_internal_impl(ctx):
    return [
        DefaultInfo(
            files = depset([ctx.file.terraform_json]),
        ),
        TerraformBackendInfo(
            backend_type = ctx.attr.backend_type,
            config_json = ctx.attr.config_json,
            terraform_json = ctx.attr.terraform_json,
        ),
    ]

_terraform_backend_internal = rule(
    implementation = _terraform_backend_internal_impl,
    attrs = {
        "backend_type": attr.string(
            mandatory = True,
        ),
        "config_json": attr.string(
            mandatory = True,
        ),
        "terraform_json": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def terraform_backend(name, backend_type, config, out = 'backend.tf.json', **kwargs):
    """Generate a .tf.json file for a Terraform backend.

    You can't use variables in Terraform backend blocks
    (https://github.com/hashicorp/terraform/issues/13022), so it is important
    for us to generate them if we want to use external variables. Also, this
    rule can be used as an input to the `terraform_remote_state` rule to
    generate a `terraform_remote_state` block for another root.

    Args:
        name: Rule name
        backend_type: String for the type of backend, like "s3"
        config: Starlark dict or struct containing configuration
    """

    wrapped_config = struct(
        terraform = struct(
            backend = {
                backend_type: config
            }
        )
    )

    write_file(
        name = name + "_write_file",
        out = out,
        content = [json.encode_indent(wrapped_config, indent = '  ')],
    )

    _terraform_backend_internal(
        name = name,
        backend_type = backend_type,
        config_json = json.encode(config),
        terraform_json = out,
        **kwargs
    )

def _terraform_remote_state_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + "_remote_state.tf.json")

    run_starlark_executor(ctx, output, ctx.file.src, ctx.files.deps, ctx.executable._starlark_executor, "encode_indent(wrap_backend_remote_state(**main()))")

    return [DefaultInfo(files = depset([output]))]

terraform_remote_state = rule(
    implementation = _terraform_remote_state_impl,
    doc = "Creates a .tf.json file defining terraform_remote_state",
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
