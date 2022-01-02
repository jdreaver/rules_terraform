load(
    "@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl",
    "jsonnet_to_json",
)

TerraformBackendInfo = provider(
    "Provider for _terraform_backend_internal rule.",
    fields = {
        "backend_type": "Name of backend, like s3",
        "config_json": "JSON config for backend",
        "terraform_json": "Reified Terraform tf.json file for the config",
    })

def _terraform_backend_internal_impl(ctx):
    return [
        TerraformBackendInfo(
            backend_type = ctx.attr.backend_type,
            config_json = ctx.attr.config_json,
            terraform_json = ctx.attr.terraform_json,
        )
    ]

_terraform_backend_internal = rule(
    implementation = _terraform_backend_internal_impl,
    attrs = {
        "backend_type": attr.string(
            mandatory = True,
        ),
        "config_json": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
        "terraform_json": attr.label(
            mandatory = True,
        ),
    },
)

def terraform_backend(name, backend_type, config_json, **kwargs):
    """Generate a .tf.json file for a Terraform backend.

    Args:
        name: Rule name
        backend_type: String for the type of backend, like "s3"
        config_json: Label for a JSON file containing an object holding the backend config.
    """

    terraform_json = name + "_backend.tf.json"

    jsonnet_to_json(
        name = name + "_jsonnet",
        src = "backend_config.jsonnet",
        outs = [terraform_json],
        tla_strs = {
            "backend_type": "s3",
        },
        tla_code_files = {
            "backend_config": config_json,
        },
    )

    _terraform_backend_internal(
        name = name,
        backend_type = backend_type,
        config_json = config_json,
        terraform_json = terraform_json,
        **kwargs
    )
