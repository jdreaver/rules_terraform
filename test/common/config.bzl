# Common config values used across multiple Terraform modules.

common_config = struct(
    state_s3_bucket = "jdreaver-rules-terraform-test-state",
    state_s3_region = "us-west-2",
    state_dynamodb_table = "terraform-statelock",
)
