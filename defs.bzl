load(
    "//internal:download.bzl",
    _download_terraform_versions = "download_terraform_versions",
    _download_terraform_provider_versions = "download_terraform_provider_versions",
    _terraform_binary = "terraform_binary",
    _terraform_provider = "terraform_provider",
)
load(
    "//internal:modules.bzl",
    _terraform_module = "terraform_module",
    _terraform_root_module = "terraform_root_module",
)
load(
    "//internal:backend.bzl",
    _terraform_backend = "terraform_backend",
    _terraform_remote_state = "terraform_remote_state",
)
load(
    "//internal:tests.bzl",
    _terraform_validate_test = "terraform_validate_test",
    _terraform_format_test = "terraform_format_test",
)

download_terraform_versions = _download_terraform_versions
download_terraform_provider_versions = _download_terraform_provider_versions
terraform_binary = _terraform_binary
terraform_provider = _terraform_provider

terraform_module = _terraform_module
terraform_root_module = _terraform_root_module

terraform_backend = _terraform_backend
terraform_remote_state = _terraform_remote_state

terraform_validate_test = _terraform_validate_test
terraform_format_test = _terraform_format_test
