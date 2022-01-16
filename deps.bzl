load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_terraform_repositories():
    pass

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)
