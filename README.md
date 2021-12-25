# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- What do we do with a terraform root that has been init'ed?
  - Wrap it in a sh_binary script that depends on the init but can run arbitrary
    Terraform commands.
- Build tests like lint and format checks
- Modules
- Terraform providers
- Ensure we don't download terraform binaries we don't actually need
