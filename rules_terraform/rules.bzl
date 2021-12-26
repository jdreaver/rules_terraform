load(":download_terraform.bzl", "TerraformBinaryInfo", "TerraformProviderInfo")

TerraformModuleInfo = provider(
    "Provider for the terraform_module rule",
    fields={
        "source_files": "depset of source Terraform files",
        "providers": "depset of providers",
    })

def _terraform_module_impl(ctx):
    # TODO: Once we have dependencies, we need to resolve transitive
    # dependencies. Same with plugins.
    return [
        TerraformModuleInfo(
            source_files = depset(ctx.files.srcs),
            providers = depset(ctx.attr.providers),
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
    providers_list = [p[TerraformProviderInfo] for p in module.providers.to_list()]
    provider_files = [p.provider for p in providers_list]

    # Create a plugin cache dir
    # TODO: This only works in Terraform < 0.14.0 or 0.13.0, check version here
    # plugin_cache = ctx.actions.declare_directory("plugin_cache")
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

TF_PLUGIN_CACHE_DIR="{plugin_cache_dir}" "$terraform" init
exec "$terraform" $@
        """.format(
            package = ctx.label.package,
            terraform = terraform_binary.short_path,
            plugin_cache_dir = plugin_cache_dir,
        ),
    )

    # TODO: Run terraform init. As you can see from all this nonsense commented
    # out code, I'm having a very hard time getting this to work inside bazel
    # (which is why we are doing it in the wrapper script currently).

    # dot_terraform = ctx.actions.declare_directory(".terraform")
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
    #     }
    # )

    # ctx.actions.run_shell(
    #     inputs = [terraform_binary] + source_files_list + cached_providers,
    #     outputs = [dot_terraform],
    #     mnemonic = "TerraformInitialize",
    #     command = "{} init {} && ls -lahR .terraform && mv .terraform {}".format(
    #         terraform_binary.path,
    #         ctx.label.package, # source_files_list[0].dirname,
    #         dot_terraform.path
    #     ),
    #     # Without use_default_shell_env I was seeing issues where "getent"
    #     # wasn't on $PATH. Could have been a NixOS thing.
    #     use_default_shell_env = True,
    #     env = {
    #         "TF_PLUGIN_CACHE_DIR": plugin_cache_dir,
    #     }
    # )

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

    runfiles = ctx.runfiles(
        files = [terraform_binary, wrapper] +
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
