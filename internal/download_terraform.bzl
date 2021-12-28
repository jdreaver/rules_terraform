def _terraform_download_impl(ctx):
    os, arch = _detect_os_arch(ctx)
    version = ctx.attr.version

    # First get SHA256SUMS file so we can get all of the individual zip SHAs
    ctx.report_progress("Downloading and extracting SHA256SUMS file")
    sha256sums_url = "https://releases.hashicorp.com/terraform/{version}/terraform_{version}_SHA256SUMS".format(
        version = version,
    )
    ctx.download(
        url = sha256sums_url,
        sha256 = ctx.attr.sha256,
        output = "terraform_sha256sums",
    )
    sha_content = ctx.read("terraform_sha256sums")
    sha_by_zip = _parse_sha_file(sha_content)
    zip = "terraform_{version}_{os}_{arch}.zip".format(
        version = version,
        os = os,
        arch = arch,
    )
    url = "https://releases.hashicorp.com/terraform/{version}/{zip}".format(
        version = version,
        zip = zip,
    )
    sha256 = sha_by_zip[zip]

    # Now download actual Terraform zip
    ctx.report_progress("Downloading and extracting Terraform")
    ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        output = "terraform",
        type = "zip",
    )

    # Put a BUILD file here so we can use the resulting binary in other bazel
    # rules.
    ctx.file("BUILD.bazel",
        """load("@rules_terraform//:defs.bzl", "terraform_binary")

terraform_binary(
    name = "terraform",
    binary = "terraform/terraform",
    version = "{version}",
    visibility = ["//visibility:public"],
)
""".format(
    version = version,
),
        executable=False
    )

def _detect_os_arch(ctx):
    if ctx.os.name == "linux":
        os = "linux"
    elif ctx.os.name == "mac os x":
        os = "darwin"
    else:
        fail("Unsupported operating system: " + ctx.os.name)

    uname_res = ctx.execute(["uname", "-m"])
    if uname_res.return_code == 0:
        uname = uname_res.stdout.strip()
        if uname == "x86_64":
            arch = "amd64"
        elif uname == "arm64":
            arch = "arm64"
        else:
            fail("Unable to determing processor architecture.")
    else:
        fail("Unable to determing processor architecture.")

    return os, arch

def _parse_sha_file(file_content):
    """Parses terraform SHA256SUMS file and returns map from zip to SHA.

    Args:
        file_content: Content of a SHA256SUMS file (see example below)

    Returns:
        A dict from a TF zip (e.g. terraform_1.1.2_darwin_amd64.zip) to zip SHA

    Here is an example couple lines from a SHA256SUMS file:

    214da2e97f95389ba7557b8fcb11fe05a23d877e0fd67cd97fcbc160560078f1  terraform_1.1.2_darwin_amd64.zip
    734efa82e2d0d3df8f239ce17f7370dabd38e535d21e64d35c73e45f35dfa95c  terraform_1.1.2_linux_amd64.zip
    """

    sha_by_zip = {}
    for line in file_content.splitlines():
        sha, _, zip = line.partition("  ")
        sha_by_zip[zip] = sha

    return sha_by_zip

terraform_download = repository_rule(
    implementation = _terraform_download_impl,
    attrs = {
        "sha256": attr.string(
            mandatory = True,
            doc = "Expected SHA-256 sum of the downloaded archive",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Version of Terraform",
        ),
    },
    doc = "Downloads a Terraform binary",
)

TerraformBinaryInfo = provider(
    "Provider for the terraform_binary rule",
    fields={
        "binary": "Path to Terraform binary",
        "version": "Version of Terraform for binary",
    })

def _terraform_binary_impl(ctx):
    # Copies the terraform binary so we can declare it as an output and mark it
    # as executable. We can't just mark the existing binary as executable,
    # unfortunately.
    output = ctx.actions.declare_file("terraform_{}".format(ctx.attr.version))
    ctx.actions.run(
        inputs = [ctx.file.binary],
        outputs = [output],
        executable = "cp",
        arguments = [
            ctx.file.binary.path,
            output.path,
        ],
    )
    return [
        DefaultInfo(
            files = depset([output]),
            executable = output,
        ),
        TerraformBinaryInfo(
            binary = output,
            version = ctx.attr.version,
        ),
    ]

terraform_binary = rule(
    implementation = _terraform_binary_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "host",
            doc = "Path to downloaded Terraform binary",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Version of Terraform",
        ),
    },
    executable = True,
)

def download_terraform_versions(versions):
    """Downloads multiple terraform versions.

    Args:
        versions: dict from terraform version to sha256 of SHA56SUMS file for that version.
    """
    for version, sha in versions.items():
        version_str = version.replace(".", "_")
        terraform_download(
            name = "terraform_{}".format(version_str),
            version = version,
            sha256 = sha,
        )

def _terraform_provider_download_impl(ctx):
    name = ctx.attr.provider_name
    os, arch = _detect_os_arch(ctx)
    version = ctx.attr.version

    # First get SHA256SUMS file so we can get all of the individual zip SHAs
    ctx.report_progress("Downloading and extracting SHA256SUMS file")
    sha256sums_url = "https://releases.hashicorp.com/terraform-provider-{name}/{version}/terraform-provider-{name}_{version}_SHA256SUMS".format(
        name = name,
        version = version,
    )
    ctx.download(
        url = sha256sums_url,
        sha256 = ctx.attr.sha256,
        output = "terraform_provider_sha256sums",
    )
    sha_content = ctx.read("terraform_provider_sha256sums")
    sha_by_zip = _parse_sha_file(sha_content)
    zip = "terraform-provider-{name}_{version}_{os}_{arch}.zip".format(
        name = name,
        version = version,
        os = os,
        arch = arch,
    )
    url = "https://releases.hashicorp.com/terraform-provider-{name}/{version}/{zip}".format(
        name = name,
        version = version,
        zip = zip,
    )
    sha256 = sha_by_zip[zip]

    # Now download actual Terraform zip
    ctx.report_progress("Downloading and extracting Terraform provider {}".format(name))
    ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        type = "zip",
    )

    # Put a BUILD file here so we can use the resulting binary in other bazel
    # rules.
    ctx.file("BUILD.bazel",
        """load("@rules_terraform//:defs.bzl", "terraform_provider")

terraform_provider(
    name = "provider",
    provider = glob(["terraform-provider-{name}_v{version}_x*"])[0],
    provider_name = "{name}",
    version = "{version}",
    source = "{source}",
    sha = "{sha}",
    platform = "{os}_{arch}",
    visibility = ["//visibility:public"]
)
""".format(
    name = name,
    version = version,
    source = ctx.attr.source,
    sha = sha256,
    os = os,
    arch = arch,
),
        executable=False
    )

terraform_provider_download = repository_rule(
    implementation = _terraform_provider_download_impl,
    attrs = {
        "provider_name": attr.string(
            mandatory = True,
        ),
        "sha256": attr.string(
            mandatory = True,
            doc = "Expected SHA-256 sum of the downloaded archive",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Version of the Terraform provider",
        ),
        "source": attr.string(
            mandatory = True,
            doc = "Source for provider used in required_providers block",
        ),
    },
    doc = "Downloads a Terraform provider",
)

TerraformProviderInfo = provider(
    "Provider for the terraform_provider rule",
    fields={
        "provider": "Path to Terraform provider",
        "provider_name": "Name of provider",
        "version": "Version of Terraform provider",
        "source": "Source for provider used in required_providers block",
        "sha": "SHA of Terraform provider binary",
        "platform": "Platform of Terraform provider binary, like linux_amd64",
    })

def _terraform_provider_impl(ctx):
    return [
        DefaultInfo(
            files = depset([ctx.file.provider]),
        ),
        TerraformProviderInfo(
            provider = ctx.file.provider,
            provider_name = ctx.attr.provider_name,
            version = ctx.attr.version,
            source = ctx.attr.source,
            sha = ctx.attr.sha,
            platform = ctx.attr.platform,
        ),
    ]

terraform_provider = rule(
    implementation = _terraform_provider_impl,
    attrs = {
        "provider": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Path to downloaded Terraform provider",
        ),
        "provider_name": attr.string(
            mandatory = True,
            doc = "Name of Terraform provider",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Version of Terraform provider",
        ),
        "source": attr.string(
            mandatory = True,
            doc = "Source for provider used in required_providers block",
        ),
        "sha": attr.string(
            mandatory = True,
            doc = "SHA of Terraform provider binary",
        ),
        "platform": attr.string(
            mandatory = True,
            doc = "Platform of Terraform provider binary, like linux_amd64",
        ),
    },
)

def download_terraform_provider_versions(provider_name, source, versions):
    """Downloads multiple terraform provider versions.

    Args:
        provider_name: string name for provider
        source: Source for provider, like registry.terraform.io/hashicorp/local
        versions: dict from terraform version to sha256 of SHA56SUMS file for that version.
    """
    for version, sha in versions.items():
        version_str = version.replace(".", "_")
        terraform_provider_download(
            name = "terraform_provider_{name}_{version_str}".format(
                name = provider_name,
                version_str = version_str,
            ),
            provider_name = provider_name,
            version = version,
            source = source,
            sha256 = sha,
        )
