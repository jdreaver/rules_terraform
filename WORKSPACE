workspace(name = "bazel_terraform_demo")

load("//rules_terraform:toolchain.bzl", "terraform_download")

terraform_download(
    name = "terraform",
    url = "https://releases.hashicorp.com/terraform/1.1.2/terraform_1.1.2_linux_amd64.zip",
    sha256 = "734efa82e2d0d3df8f239ce17f7370dabd38e535d21e64d35c73e45f35dfa95c",
)
