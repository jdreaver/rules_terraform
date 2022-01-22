load(
    ":download.bzl",
    "TerraformBinaryInfo",
)
load(
    ":modules.bzl",
    "TerraformModuleInfo",
    "TerraformRootModuleInfo",
)

def _terraform_validate_test_impl(ctx):
    root = ctx.attr.root_module[TerraformRootModuleInfo]

    # Call the wrapper script from the root module and just run validate
    exe = ctx.actions.declare_file(ctx.label.name + "_validate_test_wrapper")
    ctx.actions.write(
        output = exe,
        is_executable = True,
        content = """
set -eu

export TF_DATA_DIR=.terraform

# Avoids having the test suite complain about the aws provider plugin changing.
# Suggested here: https://github.com/hashicorp/terraform/issues/16017
export TF_SKIP_PROVIDER_VERIFY=1

"{terraform}" init -backend=false

exec "{terraform}" validate""".format(
            terraform = root.terraform_wrapper.short_path,
        ),
    )

    return [DefaultInfo(
        runfiles = root.runfiles,
        executable = exe,
    )]

terraform_validate_test = rule(
    implementation = _terraform_validate_test_impl,
    attrs = {
        "root_module": attr.label(
            mandatory = True,
            providers = [TerraformRootModuleInfo],
        ),
    },
    test = True,
)

def _terraform_format_test_impl(ctx):
    module = ctx.attr.module[TerraformModuleInfo]
    terraform_info = ctx.attr.terraform[TerraformBinaryInfo]
    terraform_binary = terraform_info.binary

    # Call terraform fmt inside the module directory
    exe = ctx.actions.declare_file(ctx.label.name + "_format_test_wrapper")
    ctx.actions.write(
        output = exe,
        is_executable = True,
        content = """
set -eu

terraform="$(pwd)/{terraform}"

cd "{module_path}"

set +e
output=$("$terraform" fmt -check -recursive)
if [ $? -ne 0 ]; then
    echo "Terraform format test failed! The following files need 'terraform fmt' to be run:\n$output"
    exit 1
fi
""".format(
    terraform = terraform_binary.short_path,
    module_path = ctx.attr.module.label.package,
),
    )

    return [DefaultInfo(
        runfiles = ctx.runfiles([terraform_binary] + module.source_files.to_list()),
        executable = exe,
    )]

terraform_format_test = rule(
    implementation = _terraform_format_test_impl,
    attrs = {
        "module": attr.label(
            mandatory = True,
            providers = [TerraformModuleInfo],
        ),
        "terraform": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "host",
            providers = [TerraformBinaryInfo],
        ),
    },
    test = True,
)
