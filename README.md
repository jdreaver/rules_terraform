# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Auto generate provider version bounds in a TF file
- Ensure we are using already downloaded providers and we aren't downloading new
  ones
  - In Terraform >= 0.13 or whatever use the incantation that says we are using
    local copies of providers.
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
- Document everything, refactor everything, etc. Make this presentable.
