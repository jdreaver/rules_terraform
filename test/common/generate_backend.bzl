# This file contains custom bazel that isn't general enough for rules_terraform.

S3BackendInfo = provider(
    "Provider for generate_s3_backend rule.",
    fields = {
        "bucket": "S3 bucket name",
        "key": "Statefile path in bucket",
        "region": "AWS region to use to communicate with bucket",
        "dynamodb_table": "DynamoDB table used for locking",
    })

def _generate_s3_backend_impl(ctx):
    output = ctx.actions.declare_file("__bazel_backend_" + ctx.label.name + ".tf.json")
    config = struct(
        terraform = struct(
            backend = struct(
                s3 = struct(
                    bucket = ctx.attr.bucket,
                    key = ctx.attr.key,
                    region = ctx.attr.region,
                    dynamodb_table = ctx.attr.dynamodb_table,
                )
            )
        )
    )
    ctx.actions.write(
        output,
        # N.B. to_json() is deprecated as of bazel 4.0 because there is a
        # json.encode() function.
        config.to_json(),
        is_executable = False,
    )
    return [
        DefaultInfo(files = depset([output])),
        S3BackendInfo(
            bucket = ctx.attr.bucket,
            key = ctx.attr.key,
            region = ctx.attr.region,
            dynamodb_table = ctx.attr.dynamodb_table,
        )
    ]

generate_s3_backend = rule(
    implementation = _generate_s3_backend_impl,
    doc = "Generate an .tf.json file to configure an S3 backend",
    attrs = {
        "bucket": attr.string(
            mandatory = True,
        ),
        "key": attr.string(
            mandatory = True,
        ),
        "region": attr.string(
            mandatory = True,
        ),
        "dynamodb_table": attr.string(
            mandatory = True,
        ),
    },
)

def _generate_s3_remote_state(ctx):
    backend = ctx.attr.backend[S3BackendInfo]
    output = ctx.actions.declare_file("__bazel_remote_state_" + ctx.label.name + ".tf.json")
    config = struct(
        data = struct(
            terraform_remote_state = {
                ctx.attr.variable_name: struct(
                    backend = "s3",
                    config = struct(
                        bucket = backend.bucket,
                        key = backend.key,
                        region = backend.region,
                    ),
                ),
            }
        )
    )
    ctx.actions.write(
        output,
        # N.B. to_json() is deprecated as of bazel 4.0 because there is a
        # json.encode() function.
        config.to_json(),
        is_executable = False,
    )
    return [
        DefaultInfo(files = depset([output])),
    ]

generate_s3_remote_state = rule(
    implementation = _generate_s3_remote_state,
    doc = "Generates a `terraform_remote_state` block from a given S3 backend configuration.",
    attrs = {
        "variable_name": attr.string(
            mandatory = True,
            doc = "Name of terraform variable to use for remote state.",
        ),
        "backend": attr.label(
            mandatory = True,
            providers = [S3BackendInfo],
        ),
    },
)
