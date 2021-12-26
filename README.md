# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Terraform providers
  - Might need to manually create `.terraform`
  - Old provider docs for 0.12.31
    https://github.com/hashicorp/terraform/blob/v0.12.31/website/docs/configuration/providers.html.md
- Modules
- Test that ensures `terraform fmt` is a no-op
- Ensure we don't download terraform binaries we don't actually need
- Simulate sharing values/config between Terraform and a separate dummy CLI tool
  (YAML files?) like at work to iron it out
- Figure out how to deal with lockfiles in newer terraform versions
  - We already pin versions and SHAs in bazel. We shouldn't need lockfiles.
  - https://www.terraform.io/cli/plugins
  - https://www.terraform.io/cli/commands/providers/lock
  - Looks like 0.13.0 is when the new provider installation methods were
    implemented, with mirrors in 0.13.2
    https://github.com/hashicorp/terraform/blob/v0.13/CHANGELOG.md#0132-september-02-2020
  - Lock file came in 0.14.0 https://github.com/hashicorp/terraform/blob/v0.14/CHANGELOG.md#0140-december-02-2020
