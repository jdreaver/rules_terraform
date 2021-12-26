# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Modules
- Make test roots for both 0.12 and the latest Terraform version to ensure we
  cover both version
- Auto generate provider version bounds in a TF file
- Figure out how to deal with lockfiles in newer terraform versions
  - We already pin versions and SHAs in bazel. We shouldn't need lockfiles.
  - https://www.terraform.io/cli/plugins
  - https://www.terraform.io/cli/commands/providers/lock
  - Looks like 0.13.0 is when the new provider installation methods were
    implemented, with mirrors in 0.13.2
    https://github.com/hashicorp/terraform/blob/v0.13/CHANGELOG.md#0132-september-02-2020
  - Lock file came in 0.14.0 https://github.com/hashicorp/terraform/blob/v0.14/CHANGELOG.md#0140-december-02-2020
- Refactor terraform init to make it way less nasty
  - Maybe just using Terraform >= 1.0 will be less pain
  - We have to use `run_shell` so we can `mv .terraform` to its actual location
    because for some reason TF_DATA_DIR is ignored.
- Use amd64 for Terraform versions that don't have arm64
- Test that ensures `terraform fmt` is a no-op
- Ensure we don't download terraform binaries we don't actually need
- Simulate sharing values/config between Terraform and a separate dummy CLI tool
  (YAML files?) like at work to iron it out
