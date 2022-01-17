load("../common/config.star", "state_dynamodb_table", "state_s3_bucket")

def main():
    return {
        "bucket_name": state_s3_bucket,
        "dynamodb_table_name": state_dynamodb_table,
    }
