load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_terraform_dependencies():
    _maybe(
        http_archive,
        name = "io_bazel_rules_jsonnet",

        # sha256 = "7f51f859035cd98bcf4f70dedaeaca47fe9fbae6b199882c516d67df416505da",
        # strip_prefix = "rules_jsonnet-0.3.0",
        # urls = ["https://github.com/bazelbuild/rules_jsonnet/archive/0.3.0.tar.gz"],

        # 0.4.0, doesn't work yet
        sha256 = "d20270872ba8d4c108edecc9581e2bb7f320afab71f8caa2f6394b5202e8a2c3",
        strip_prefix = "rules_jsonnet-0.4.0",
        urls = ["https://github.com/bazelbuild/rules_jsonnet/archive/0.4.0.tar.gz"],
    )

    _maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "7904dbecbaffd068651916dce77ff3437679f9d20e1a7956bff43826e7645fcc",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.25.1/rules_go-v0.25.1.tar.gz",
            "https://github.com/bazelbuild/rules_go/releases/download/v0.25.1/rules_go-v0.25.1.tar.gz",
        ],
    )

    _maybe(
        http_archive,
        name = "bazel_gazelle",
        sha256 = "222e49f034ca7a1d1231422cdb67066b885819885c356673cb1f72f748a3c9d4",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
            "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.3/bazel-gazelle-v0.22.3.tar.gz",
        ],
    )

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)
