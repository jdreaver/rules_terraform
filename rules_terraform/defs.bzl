load(
    ":download_terraform.bzl",
    _download_terraform_versions = "download_terraform_versions",
    _download_terraform_provider_versions = "download_terraform_provider_versions",
)
load(
    ":rules.bzl",
    _terraform_module = "terraform_module",
    _terraform_root_module = "terraform_root_module",
    _terraform_validate_test = "terraform_validate_test",
)

download_terraform_versions = _download_terraform_versions
download_terraform_provider_versions = _download_terraform_provider_versions
terraform_module = _terraform_module
terraform_root_module = _terraform_root_module
terraform_validate_test = _terraform_validate_test
