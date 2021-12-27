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
    if terraform_version < "0.13": # TODO: Does this actually work with 0.14?
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

        # lock_json_output = ctx.actions.declare_file(".terraform/plugins/{}/lock.json".format(
        #     provider.platform,
        # ))
        # # Manually construct json because the version of bazel I'm writing this on
        # # doesn't have the json module.
        # lock_json_strings = ["{"] + ['  "{}": "{}"'.format(provider.provider_name, provider.sha) for provider in providers_list] + ["}"]
        # ctx.actions.write(
        #     lock_json_output,
        #     "\n".join(lock_json_strings),
        # )
    else:
        fail("Don't know how to construct .terraform outputs for terraform versions >= 0.13")

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

    # Run terraform init
    dot_terraform = ctx.actions.declare_directory(".terraform")
    ctx.actions.run_shell(
        inputs = [terraform_binary] + source_files_list + cached_providers,
        outputs = [dot_terraform],
        mnemonic = "TerraformInitialize",
        command = 'terraform="$(realpath {binary})" && cd {package} && ls -lah && "$terraform" init && cd - && rm -r {dot_terraform} && mv "{package}/.terraform" {dot_terraform}'.format(
            binary = terraform_binary.path,
            package = ctx.label.package,
            dot_terraform = dot_terraform.path,
        ),
        # Without use_default_shell_env I was seeing issues where "getent"
        # wasn't on $PATH. Could have been a NixOS thing.
        use_default_shell_env = True,
        env = {
            "TF_PLUGIN_CACHE_DIR": plugin_cache_dir,
            # TODO: This doesn't work, and this is why we need to run "mv" and use run_shell
            # "TF_DATA_DIR": dot_terraform.path,
        }
    )

    # TODO: Ideally we use this instead of run_shell, but having to actually move
    # .terraform is a huge drag.
    # args = ctx.actions.args()
    # args.add("init")
    # args.add("-backend=false")
    # args.add(ctx.label.package)
    # ctx.actions.run(
    #     executable = terraform_binary,
    #     inputs = source_files_list + cached_providers,
    #     outputs = [dot_terraform],
    #     mnemonic = "TerraformInitialize",
    #     arguments = [args],
    #     # Without use_default_shell_env I was seeing issues where "getent"
    #     # wasn't on $PATH. Could have been a NixOS thing.
    #     use_default_shell_env = True,
    #     env = {
    #         "TF_PLUGIN_CACHE_DIR": plugin_cache_dir,
    #         "TF_DATA_DIR": dot_terraform.path,
    #     }
    # )

    runfiles = ctx.runfiles(
        files = [terraform_binary, wrapper, dot_terraform] +
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
