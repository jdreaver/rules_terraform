# This file contains custom bazel that isn't general enough for rules_terraform.

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
    return [DefaultInfo(files = depset([output]))]

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
