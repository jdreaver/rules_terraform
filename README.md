# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Figure out what to do with initialized Terraform
  - Ideally we can run terraform in the actual source directory, but with links
    to modules, generated files, plugins, etc all handled. That might not be
    possible though, so maybe we need to run it in some hidden bazel directory.
- Test that ensures `terraform fmt` is a no-op
- Modules
- Terraform providers
- Ensure we don't download terraform binaries we don't actually need
- Simulate sharing values/config between Terraform and a separate dummy CLI tool
  (YAML files?) like at work to iron it out
