# Common config values used across multiple Terraform modules.

state_s3_bucket = "jdreaver-rules-terraform-test-state"
state_s3_region = "us-west-2"
state_dynamodb_table = "terraform-statelock"

def create_backend_config(key):
    return {
        "bucket": state_s3_bucket,
        "region": state_s3_region,
        "dynamodb_table": state_dynamodb_table,
        "key": key,
    }
