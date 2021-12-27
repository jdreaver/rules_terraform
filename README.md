# Bazel Terraform Demo

This is a proof of concept for integrating bazel with Terraform.

## Resources

There are a few Github projects implementing Terraform in bazel, but this is the
best one by far: https://github.com/dvulpe/bazel-terraform-rules

## TODO:

- Ensure we are using already downloaded providers and we aren't downloading new
  ones
  - Looks like 0.13.0 is when the new provider installation methods were
    implemented, with mirrors in 0.13.2
    https://github.com/hashicorp/terraform/blob/v0.13/CHANGELOG.md#0132-september-02-2020
	- https://www.terraform.io/cli/config/config-file#explicit-installation-method-configuration
	- We can use the filesystem_mirror block
- Use amd64 for Terraform versions that don't have arm64
- Test that ensures `terraform fmt` is a no-op
- Ensure we don't download terraform binaries we don't actually need
- Simulate sharing values/config between Terraform and a separate dummy CLI tool
  (YAML files?) like at work to iron it out
  - https://github.com/bazelbuild/bazel/issues/13300
- Document everything, refactor everything, etc. Make this presentable.

## Why wrap Terraform in bazel?

At work we use [bazel](https://bazel.build/) to build all most of our code into
artifacts like tarballs of compiled binaries and container images. Bazel has
been great because it gives us consistency, speed, and reproducibility in our
builds, even at such a huge scale.

Unfortunately, our infrastructure as code tooling at work (which includes
Terraform) is _not_ currently as nice as our bazel builds for other languages.
We have _thousands_ of Terraform roots written by thousands of engineers, with
all kinds external references to other Terraform roots and modules, YAML files
with common variable values (extracted with an external script at runtime),
references to/from external tooling that we use just for ASGs and security
groups, etc. Our Terraform tests are slow because we have to run `terraform
init` in thousands of Terraform root modules just so we can run `terraform
validate`.

We already have lots of experience with bazel, and we know our current usage of
Terraform won't scale, so this repo is an experiment in wrapping Terraform in
bazel to see if we can solve lots of our infrastructure as code problems.

## Usage

(TODO: Flesh this out once API is more stable)

- Add incantations to your `WORKSPACE` file to declare which Terraform versions
  and Terraform provider versions you are using.
- Put a `BUILD`/`BUILD.bazel` file in each Terraform module directory.
- Add a `terraform_module` rule for each module, `terraform_root_module` for
  each root module, and `terraform_*_test` for each kind of test you want to run
  on your modules.

## Detailed discussion of problems being solved

### Automatically download correct versions of Terraform and providers

### Build a DAG of Terraform root modules so we can reason about downstream/upstream changes

### Share variables between Terraform and external tooling

### Cache builds and tests

### (Maybe) Generate boilerplate Terraform code for dependencies and references from bazel
