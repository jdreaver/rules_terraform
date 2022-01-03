load(
    "//internal:download_terraform.bzl",
    _download_terraform_versions = "download_terraform_versions",
    _download_terraform_provider_versions = "download_terraform_provider_versions",
    _terraform_binary = "terraform_binary",
    _terraform_provider = "terraform_provider",
)
load(
    "//internal:rules.bzl",
    _terraform_module = "terraform_module",
    _terraform_root_module = "terraform_root_module",
    _terraform_validate_test = "terraform_validate_test",
    _terraform_format_test = "terraform_format_test",
)
load(
    "//internal:backend.bzl",
    _terraform_backend = "terraform_backend",
    _terraform_remote_state = "terraform_remote_state",
)

download_terraform_versions = _download_terraform_versions
download_terraform_provider_versions = _download_terraform_provider_versions
terraform_binary = _terraform_binary
terraform_provider = _terraform_provider

terraform_module = _terraform_module
terraform_root_module = _terraform_root_module
terraform_validate_test = _terraform_validate_test
terraform_format_test = _terraform_format_test

terraform_backend = _terraform_backend
terraform_remote_state = _terraform_remote_state
