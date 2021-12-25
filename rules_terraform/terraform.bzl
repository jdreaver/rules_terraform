toolchains = {
    "linux_amd64": {
        "exec_compatible_with": [
            "@bazel_tools//platforms:linux",
            "@bazel_tools//platforms:x86_64",
        ],
        "target_compatible_with": [
            "@bazel_tools//platforms:linux",
            "@bazel_tools//platforms:x86_64",
        ],
        "toolchain":":terraform_linux_amd64",
        "toolchain_type":"//rules_terraform:toolchain_type",
    },
}

def _terraform_download_impl(ctx):
    ctx.file("BUILD.bazel",
        """
load("@bazel_terraform_demo//rules_terraform:terraform.bzl", "declare_terraform_toolchains")

declare_terraform_toolchains()

filegroup(
    name = "terraform_executable",
    srcs = ["terraform/terraform"],
    visibility = ["//visibility:public"]
)

""",
        executable=False
    )
    ctx.report_progress("Downloading and extracting Terraform")
    ctx.download_and_extract(
        url = ctx.attr.url,
        sha256 = ctx.attr.sha256,
        output = "terraform",
        type = "zip",
    )

terraform_download = repository_rule(
    implementation = _terraform_download_impl,
    attrs = {
        "url": attr.string(
            mandatory = True,
            doc = "URL to download Terraform zip file",
        ),
        "sha256": attr.string(
            mandatory = True,
            doc = "Expected SHA-256 sum of the downloaded archive",
        ),
        # "platform": attr.string(
        #     mandatory = True,
        #     values = ["darwin", "linux", "windows"],
        #     doc = "Host operating system for the Terraform binary",
        # ),
        # "arch": attr.string(
        #     mandatory = True,
        #     values = ["amd64", "arm"],
        #     doc = "Host architecture for the Terraform binary",
        # ),
    },
    doc = "Downloads a Terraform binary",
)

def declare_terraform_toolchains():
    for name, toolchain in toolchains.items():
        native.toolchain(
            name = "terraform_{0}_toolchain".format(name),
            exec_compatible_with = toolchain["exec_compatible_with"],
            target_compatible_with = toolchain["target_compatible_with"],
            toolchain = toolchain["toolchain"],
            toolchain_type = toolchain["toolchain_type"]
        )

TerraformInitInfo = provider(
    "Files produced by terraform init",
    fields={
        "source_files": "depset of source Terraform files",
        "dot_terraform": ".terraform directory from terraform init",
    })

def _terraform_init(ctx):
    srcs = depset(ctx.files.srcs)
    output = ctx.actions.declare_directory(".terraform")
    ctx.actions.run(
        executable = ctx.executable._exec,
        inputs = srcs.to_list(),
        outputs = [output],
        mnemonic = "TerraformInitialize",
        arguments = [
            "init",
            "-out={0}".format(output.path),
            srcs.to_list()[0].dirname, # TODO: Better way to get this?
        ],
    )
    return [
        DefaultInfo(files = srcs),
        TerraformInitInfo(
            source_files = srcs,
            dot_terraform = output
        )
    ]

terraform_init = rule(
    implementation = _terraform_init,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "_exec": attr.label(
            default = Label("@terraform//:terraform_executable"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    #outputs = {"out": "%{name}.out"},
)
