load(":download_terraform.bzl", _download_terraform_versions = "download_terraform_versions")
load(
    ":rules.bzl",
    _terraform_init = "terraform_init",
    _terraform_run = "terraform_run",
    _terraform_validate_test = "terraform_validate_test",
)

download_terraform_versions = _download_terraform_versions
terraform_init = _terraform_init
terraform_run = _terraform_run
terraform_validate_test = _terraform_validate_test
