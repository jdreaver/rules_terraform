load("@bazel_skylib//rules:write_file.bzl", "write_file")

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

def _terraform_remote_state(ctx):
    backend = ctx.attr.backend[TerraformBackendInfo]
    backend_type = backend.backend_type
    config = json.decode(backend.config_json)

    output = ctx.actions.declare_file(ctx.label.name + "_remote_state.tf.json")
    config = struct(
        data = struct(
            terraform_remote_state = {
                ctx.attr.variable_name: struct(
                    backend = backend_type,
                    config = config,
                ),
            }
        )
    )
    ctx.actions.write(
        output,
        json.encode_indent(config, indent = '  '),
        is_executable = False,
    )
    return [
        DefaultInfo(files = depset([output])),
    ]

terraform_remote_state = rule(
    implementation = _terraform_remote_state,
    doc = "Generates a `terraform_remote_state` block from a given backend configuration.",
    attrs = {
        "variable_name": attr.string(
            mandatory = True,
            doc = "Name of terraform variable to use for remote state.",
        ),
        "backend": attr.label(
            mandatory = True,
            providers = [TerraformBackendInfo],
            doc = "Label for terraform_backend to reference.",
        ),
    },
)
