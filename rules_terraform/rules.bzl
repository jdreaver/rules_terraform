TerraformInitInfo = provider(
    "Files produced by terraform init",
    fields={
        "terraform": "Terraform executable used to init",
        "source_files": "depset of source Terraform files",
        "dot_terraform": ".terraform directory from terraform init",
    })

def _terraform_init_impl(ctx):
    output = ctx.actions.declare_directory(".terraform")
    ctx.actions.run(
        executable = ctx.executable.terraform,
        inputs = ctx.files.srcs,
        outputs = [output],
        mnemonic = "TerraformInitialize",
        arguments = [
            "init",
            #"-out={0}".format(output.path),
            #"-chdir={}".format(srcs.to_list()[0].dirname), # TODO: Better way to get this?
        ],
    )
    return [
        # Provide output as default file so we can run this rule in isolation
        DefaultInfo(files = depset([output])),
        TerraformInitInfo(
            terraform = ctx.executable.terraform,
            source_files = depset(ctx.files.srcs),
            dot_terraform = output
        )
    ]

terraform_init = rule(
    implementation = _terraform_init_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "terraform": attr.label(
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
)

def _terraform_run_impl(ctx):
    init = ctx.attr.init[TerraformInitInfo]

    # Create a wrapper script that runs terraform in a bazel run directory with
    # all of the necessary files symlinked.
    exe = ctx.actions.declare_file(ctx.label.name + "_run_wrapper")
    ctx.actions.write(
        output = exe,
        is_executable = True,
        content = """
set -eu

terraform="$(realpath {terraform})"

cd "{package}"

exec "$terraform" $@
        """.format(
            package = ctx.label.package,
            terraform = init.terraform.path,
        ),
    )

    runfiles = ctx.runfiles(
        files = [init.terraform, init.dot_terraform],
        transitive_files = init.source_files,
    )
    return [DefaultInfo(
        runfiles = runfiles,
        executable = exe,
    )]

terraform_run = rule(
    implementation = _terraform_run_impl,
    attrs = {
        "init": attr.label(
            mandatory = True,
            providers = [TerraformInitInfo],
        ),
    },
    executable = True,
)

# TODO: Potentially DRY this between the run script, or somehow use the run
# script in this rule. In fact, maybe creating the run script wrapper should be
# a part of some terraform_root rule instead of being split out of
# terraform_init.
#
# Also, maybe validate should just be done right after init.
def _terraform_validate_test_impl(ctx):
    init = ctx.attr.init[TerraformInitInfo]

    # Create a wrapper script that runs terraform in a bazel run directory with
    # all of the necessary files symlinked.
    exe = ctx.actions.declare_file(ctx.label.name + "_validate_test_wrapper")
    ctx.actions.write(
        output = exe,
        is_executable = True,
        content = """
set -eu

terraform="$(realpath {terraform})"

cd "{package}"

exec "$terraform" validate
        """.format(
            package = ctx.label.package,
            terraform = init.terraform.path,
        ),
    )

    runfiles = ctx.runfiles(
        files = [init.terraform, init.dot_terraform],
        transitive_files = init.source_files,
    )
    return [DefaultInfo(
        runfiles = runfiles,
        executable = exe,
    )]

terraform_validate_test = rule(
    implementation = _terraform_validate_test_impl,
    attrs = {
        "init": attr.label(
            mandatory = True,
            providers = [TerraformInitInfo],
        ),
    },
    test = True,
)
