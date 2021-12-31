provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "jdreaver-rules-terraform-test-state"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name         = "terraform-statelock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
