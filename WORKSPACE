workspace(name = "bazel_terraform_demo")

load(
    "//rules_terraform:defs.bzl",
    "download_terraform_versions",
    "download_terraform_provider_versions",
)

download_terraform_versions({
    # These are SHAs of the SHA265SUM file for a given version. They can be
    # found with e.g.:
    # curl https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_SHA256SUMS | sha256sum
    "0.12.31": "f9a95c24c77091a1ae0ca2539f39ccfb2639c59934858fada6f4950541386fad",
    "1.1.2": "20e4115a8c6aff07421ebc6645056f9a6605ab5a196475ab46a65fea71b6b090",
})

download_terraform_provider_versions(
    "local",
    {
        "2.1.0": "dae594d82be6be5ee83f8d081cc8a05af45ac1bbf7fdb8bea16ab4c1d6032043",
    },
)
