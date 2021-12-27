load(":download_terraform.bzl", "TerraformBinaryInfo", "TerraformProviderInfo")

TerraformModuleInfo = provider(
    "Provider for the terraform_module rule",
    fields={
        "source_files": "depset of source Terraform files",
        "modules": "depset of modules",
        "providers": "depset of providers",
    })

def _terraform_module_impl(ctx):
    return [
        TerraformModuleInfo(
            source_files = depset(
                ctx.files.srcs,
                transitive = [dep[TerraformModuleInfo].source_files for dep in ctx.attr.deps]
            ),
            modules = depset(
                ctx.attr.deps,
                transitive = [dep[TerraformModuleInfo].modules for dep in ctx.attr.deps]
            ),
            providers = depset(
                ctx.attr.providers,
                transitive = [dep[TerraformModuleInfo].providers for dep in ctx.attr.deps]
            ),
        )
    ]

terraform_module = rule(
    implementation = _terraform_module_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "providers": attr.label_list(
            mandatory = True,
            providers = [TerraformProviderInfo],
        ),
        "deps": attr.label_list(
            providers = [TerraformModuleInfo],
        ),
    },
)

TerraformRootModuleInfo = provider(
    "Provider for the terraform_root_module rule",
    fields={
        "terraform_wrapper": "Terraform wrapper script to run terraform in this rule's output directory",
        "runfiles": "depset of collected files needed to run",
    })

def _terraform_root_module_impl(ctx):
    terraform_info = ctx.attr.terraform[TerraformBinaryInfo]
    terraform_binary = terraform_info.binary
    terraform_version = terraform_info.version

    module = ctx.attr.module[TerraformModuleInfo]
    source_files_list = module.source_files.to_list()
    modules_list = module.modules.to_list()
    providers_list = [p[TerraformProviderInfo] for p in module.providers.to_list()]
    provider_files = [p.provider for p in providers_list]

    # Create a plugin cache dir
    plugin_cache_dir = "plugin_cache"
    cached_providers = []
    for provider in providers_list:
        output = ctx.actions.declare_file("{}/{}/{}".format(
            plugin_cache_dir,
            provider.platform,
            provider.provider.basename,
        ))
        ctx.actions.run(
            inputs = [provider.provider],
            outputs = [output],
            executable = "cp",
            arguments = [
                provider.provider.path,
                output.path,
            ],
        )
        cached_providers.append(output)

    # Create a wrapper script that runs terraform in a bazel run directory with
    # all of the necessary files symlinked.
    wrapper = ctx.actions.declare_file(ctx.label.name + "_run_wrapper")
    ctx.actions.write(
        output = wrapper,
        is_executable = True,
        content = """
set -eu

terraform="$(realpath {terraform})"

cd "{package}"

exec "$terraform" $@
        """.format(
            package = ctx.label.package,
            terraform = terraform_binary.short_path,
        ),
    )

    # Declare files we are going to generate from init. Note that
    # .terraform.lock.hcl is only used in Terraform >= 0.14, so we just touch it
    # if we are below that version.
    dot_terraform = ctx.actions.declare_directory(".terraform")
    terraform_lock_file = ctx.actions.declare_file(".terraform.lock.hcl")

    # Write init script to run terraform init
    init_script = ctx.actions.declare_file("_terraform_init_script")
    ctx.actions.write(
        init_script,
        """set -eu

# Record absolute path of terraform binary because we are about to
# change directories
terraform="$(realpath {binary})"

# Move to Terraform root directory so paths are relative to here
pushd {package}
"$terraform" init
{touch_lock_file}

# Go back to main execution directory and move .terraform to where we
# declared it to be (it is in some deep bazel-out directory)
popd
rm -r {dot_terraform}
mv "{package}/.terraform" {dot_terraform}
mv "{package}/.terraform.lock.hcl" {terraform_lock_file}
        """.format(
            binary = terraform_binary.path,
            package = ctx.label.package,
            # Use touch to create fake lock file
            touch_lock_file = "touch .terraform.lock.hcl" if terraform_version <= "0.14" else "",
            dot_terraform = dot_terraform.path,
            terraform_lock_file = terraform_lock_file.path
        ),
        is_executable = True,
    )

    # Run terraform init script
    ctx.actions.run(
        inputs = [terraform_binary] + source_files_list + cached_providers,
        outputs = [dot_terraform, terraform_lock_file],
        mnemonic = "TerraformInitialize",
        executable = init_script,
        # Without use_default_shell_env I was seeing issues where "getent"
        # wasn't on $PATH. Could have been a NixOS thing.
        use_default_shell_env = True,
        env = {
            "TF_PLUGIN_CACHE_DIR": plugin_cache_dir,
            # TODO: This doesn't work at all for some reason. Just straight up
            # ignored by Terraform.
            # "TF_DATA_DIR": dot_terraform.path,
        }
    )

    runfiles = ctx.runfiles(
        files = [terraform_binary, wrapper, dot_terraform, terraform_lock_file] +
                source_files_list + cached_providers,
    )
    return [
        DefaultInfo(
            runfiles = runfiles,
            executable = wrapper,
        ),
        TerraformRootModuleInfo(
            terraform_wrapper = wrapper,
            runfiles = runfiles,
        )
    ]

terraform_root_module = rule(
    implementation = _terraform_root_module_impl,
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
    executable = True,
)

def _terraform_validate_test_impl(ctx):
    root = ctx.attr.root_module[TerraformRootModuleInfo]

    # Call the wrapper script from the root module and just run validate
    exe = ctx.actions.declare_file(ctx.label.name + "_validate_test_wrapper")
    ctx.actions.write(
        output = exe,
        is_executable = True,
        content = """exec "{terraform}" validate""".format(
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
