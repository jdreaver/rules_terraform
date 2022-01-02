workspace(name = "rules_terraform")

load("//:deps.bzl", "rules_terraform_dependencies")
rules_terraform_dependencies()

load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_repositories")
jsonnet_repositories()

# load("@jsonnet_go//bazel:repositories.bzl", "jsonnet_go_repositories")
# jsonnet_go_repositories()
# load("@jsonnet_go//bazel:deps.bzl", "jsonnet_go_dependencies")
# jsonnet_go_dependencies()

# Once we use rules_jsonnet 0.4.0:
# https://github.com/bazelbuild/rules_jsonnet/commit/fa78c32a4bc77a618eff04399db8fbe603e203fa
load("@google_jsonnet_go//bazel:repositories.bzl", "jsonnet_go_repositories")
jsonnet_go_repositories()
load("@google_jsonnet_go//bazel:deps.bzl", "jsonnet_go_dependencies")
jsonnet_go_dependencies()
