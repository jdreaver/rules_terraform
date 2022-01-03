# rules_terraform

This is a WIP set of [Bazel](https://bazel.build/) rules for Terraform.

## Usage

(TODO: Flesh this out once API is more stable)

- Add incantations to your `WORKSPACE` file to declare which Terraform versions
  and Terraform provider versions you are using.
- Put a `BUILD`/`BUILD.bazel` file in each Terraform module directory.
- Add a `terraform_module` rule for each module, `terraform_root_module` for
  each root module, and `terraform_*_test` for each kind of test you want to run
  on your modules.

## Features

- Automatically download Terraform and provider binaries and cache them via
  bazel.
- Cache test results like `terraform fmt -check` and `terraform validate` and
  only re-run them as needed.
- Hermetically build Terraform dependencies, like external modules and providers.
- Be explicit about Terraform module dependencies and use `bazel query` to build
  a DAG of module dependencies.
- Auto-generate `backend` blocks and `terraform_remote_state` based on other
  modules' backend blocks.
  - (TODO: This is currently only implemented for S3 and is inlined into the
    `test` code. Make this more general by e.g. providing a JSON object for
    backend config and passing that around.)

## TODO

- Set up
  [buildifier](https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md)
  in this repo and add a CI test for ensuring everything is formatted correctly
  and there are no lint warnings.
- Figure out how to make DAG of terraform roots
  - For example, make it clear that the state S3 bucket and DynamoDB table are
    created in `tf_bootstrap_state` so that shows up as a dependency of the
    other modules. Do we have to reify the backend config somehow in
    `tf_bootstrap_state`'s BUILD file, and then read that as a target in other
    files?
  - Maybe "making a DAG of roots" is the wrong way to think about it. The real
    problem we want to solve is given some set of files that changed, what do we
    need to deploy. That might involve an `rdeps` query filtered on
    `terraform_root_module` rules. It also means we might want to reify configs
    in `BUILD` files so they get a label.
  - This feels like a fool's errand without a more specific goal. Maybe we have
    to settle for an 80/20 solution of explicitly annotating dependencies, kind
    of like in Terragrunt's `dependencies` blocks?
- Investigate auto generating BUILD files for existing roots. Gazelle perhaps?
  Read `.terraform` structure?
- Try implementing toolchain again so we can pick a default Terraform version
  - In the real world we probably want to be explicit, but for the `terraform
    fmt` test we can use whatever.
- Ensure we are using already downloaded providers and we aren't downloading new
  ones
  - Looks like 0.13.0 is when the new provider installation methods were
    implemented, with mirrors in 0.13.2
    https://github.com/hashicorp/terraform/blob/v0.13/CHANGELOG.md#0132-september-02-2020
	- https://www.terraform.io/cli/config/config-file#explicit-installation-method-configuration
	- We can use the filesystem_mirror block
  - Try making `terraform init` faster. I think downloading providers is the
    slowest part. Maybe we can symlink providers directly? (It looks like we
    actually are already just symlinking providers, FWIW)
- Ensure we don't download terraform binaries we don't actually need
- Simulate sharing values/config between Terraform and a separate dummy CLI tool
  (YAML files?) like at work to iron it out
  - https://github.com/bazelbuild/bazel/issues/13300
  - Rule of thumb: values that need to be shared but are known ahead of time,
    like S3 bucket names, VPC CIDRs, DNS names, etc, are great candidates for
    things that could be shared via `.bzl` files. However, it is not clear what
    we should do with "generated identifiers" (VPC IDs, load balancer DNS
    endpoints, etc). This could be queried from Terraform state, queried at
    runtime, etc. Also, even if we query them at runtime, we then might need to
    "join" them with other values, like VPC CIDRs. Not sure.
  - We currently use starlark values to generate JSON for generating Terraform
    variables/backends, but I worry about the scalability and ergonomics of
    that. Specifically, I think this moves a lot of work into the bazel starlark
    interpreter in the analyze step instead of the execute step.
    - Consider using jsonnet (e.g. <https://github.com/bazelbuild/rules_jsonnet>)
      to generate JSON ergonomically. (SEE BRANCH `jsonnet`)
	- [Skycfg](https://github.com/stripe/skycfg) or a small starlark execution
      wrapper in Go is an obvious alternative. Then we get a strict separation
      between buidl (.bzl) starlark and configuration starlark. Can JSON
      encode/decode via the native starlark functions.
	- Coolest new kid on the block for this is [CUE](https://cuelang.org/)
- Document everything, refactor everything, etc. Make this presentable.
- Add a top-level test asserting all S3 backend keys are unique. Duplicating
  keys because of a copy/paste error is really common.
- Consider using
  [genquery](https://docs.bazel.build/versions/main/be/general.html#genquery)
  for common queries, like number of terraform roots on each version
- Make sure to re-enable `bazel test /...` in root workspace in CI once there is
  something to test

## Why wrap Terraform in Bazel?

At work we use [Bazel](https://bazel.build/) to build all most of our code into
artifacts like tarballs of compiled binaries and container images. Bazel has
been great because it gives us consistency, speed, and reproducibility in our
builds, even at such a huge scale.

Unfortunately, our infrastructure as code tooling at work (which includes
Terraform) is _not_ currently as nice as our Bazel builds for other languages.
We have _thousands_ of Terraform roots written by thousands of engineers, with
all kinds external references to other Terraform roots and modules, YAML files
with common variable values (extracted with an external script at runtime),
references to/from external tooling that we use just for ASGs and security
groups, etc. Our Terraform tests are slow because we have to run `terraform
init` in thousands of Terraform root modules just so we can run `terraform
validate`.

We already have lots of experience with Bazel, and we know our current usage of
Terraform won't scale, so this repo is an experiment in wrapping Terraform in
Bazel to see if we can solve lots of our infrastructure as code problems.

### Cache downloads, builds, and tests

Bazel aggressively caches all nodes in the build graph. That means downloaded
Terraform binaries, downloaded Terraform providers, builds of `.terraform`, and
test executions are all cached. This means that incremental runs of `terraform
init` and any tests are as fast as possible in CI; you won't rebuild
`.terraform` or rerun a test unless some upstream dependency actually changed.

#### (TODO) Cache providers centrally for all roots

(The TODO here is ensuring providers aren't copied between roots. This might
only be possible for versions >= 0.13.2 and with `filesystem_mirror`. This is
fantastic because we might be able to store thousands of roots in a single
tarball with minimal space; it is almost entirely a bunch of symlinks.)

### Build a DAG of Terraform root modules so we can reason about downstream/upstream changes

Bazel requires you to be extremely explicit about dependencies. Bazel actions
are executed in sandboxes that are as isolated as possible from the host system,
and only declared dependencies are brought into the sandbox. There are all kinds
of caveats with this, but the relevant bit for Terraform is if you leave out a
dependency on a module, provider, or some other Bazel file, then Bazel will
complain very loudly.

This specificity allows us to reason about the dependencies between Terraform
and even external code that interfaces with Terraform. We can use Bazel's
[extensive query language](https://docs.bazel.build/versions/main/query.html) to
inspect the dependency graph. For example, to view which terraform roots depend
on a given module, we can do:

```
$ bazel query "kind(terraform_root_module, rdeps(//terraform/..., //terraform/time_module:module))" --output package
terraform/0_12_31
terraform/1_1_2
```

Also, how many Terraform modules are using a given Terraform version?

```
$ bazel query "attr(terraform, @terraform_1_1_2//:terraform, //...)" --output package
terraform/1_1_2
terraform/time_module
```

How about just root modules?

```
$ bazel query "kind(terraform_root_module, attr(terraform, @terraform_1_1_2//:terraform, //...))" --output package
terraform/1_1_2
```

How about a count of root modules on each version?

```
$ bazel query "labels(terraform, kind(terraform_root_module, //...))" | sort | uniq -c
      1 @terraform_0_12_31//:terraform
      1 @terraform_1_1_2//:terraform
```

### Share variables between Terraform and external tooling

(TODO: This is trivial if we put shared variables in `.bzl` files, which
honestly is not a bad idea. We might want to figure out a migration path from
YAML files first though.)

### (TODO) Generate boilerplate Terraform code for dependencies and references from Bazel

(TODO: We might want to trivially import Starlark or YAML values like ints,
strings, structs, etc into Terraform data structures for ease of use. This is
likely possible with some simple build rule to spit out a Starlark value into a
`.tf` file that populates a `local` variable.)
