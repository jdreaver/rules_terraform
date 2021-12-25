workspace(name = "bazel_terraform_demo")

load("//rules_terraform:terraform.bzl", "download_terraform_versions")

download_terraform_versions({
    # These are SHAs of the SHA265SUM file for a given version. They can be
    # found with e.g.:
    # curl https://releases.hashicorp.com/terraform/0.12.31/terraform_0.12.31_SHA256SUMS | sha256sum
    "0.12.31": "f9a95c24c77091a1ae0ca2539f39ccfb2639c59934858fada6f4950541386fad",
    "1.1.2": "20e4115a8c6aff07421ebc6645056f9a6605ab5a196475ab46a65fea71b6b090",
})
