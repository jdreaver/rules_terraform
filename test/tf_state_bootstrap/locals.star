# TODO: This import path is relative to the WORKSPACE root. Should we explicitly
# use the bazel "//common/..." syntax, or should we implement relative paths?
load("common/config.star", "state_dynamodb_table", "state_s3_bucket")

def main():
    return {
        "bucket_name": state_s3_bucket,
        "dynamodb_table_name": state_dynamodb_table,
    }
