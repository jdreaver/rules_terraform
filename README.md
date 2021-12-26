# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Move `terraform init` and creating `.terraform` into bazel rule instead of
  doing it in wrapper script.
  - Current system is bad too because it fetches undeclared providers at runtime
    from network.
  - I think the problem is `.terraform` is created with
    `ctx.actions.declare_directory`, and we correctly pass that around as a
    runfile, but we don't pass around everything under that. Maybe we need to
    explicitly declare `lock.json`, the providers, etc.
	```
    .terraform
    └── plugins
        └── linux_amd64
            ├── lock.json
            └── terraform-provider-local_v2.1.0_x5 -> /home/david/.cache/bazel/_bazel_david/2203281fd02fc20d7232b7c89f51aaea/execroot/bazel_terraform_demo/bazel-out/k8-fastbuild/bin/terraform/plugin_cache/linux_amd64/terraform-provider-local_v2.1.0_x5
    ```
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
