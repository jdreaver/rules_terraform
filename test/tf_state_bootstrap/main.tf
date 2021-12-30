provider "aws" {
  region = "us-west-2"
}

# TODO: This backend block doesn't work! We can't initialize it in bazel without
# AWS creds, and we can't initialize it after init because .terraform is
# write-only.
#
# N.B. When this is first created, we need to comment out the backend block and
# manually store the state in the local filesystem. Once the bucket exists, we
# can store the state in the bucket by uncommenting this block:
#
# $ terraform apply -state=/tmp/booststrap.tfstate
# (uncomment this block)
# $ terraform init -lock=false
# $ terraform apply -state=/tmp/booststrap.tfstate
#
# terraform {
#   backend "s3" {
#     # N.B. Make sure this matches bucket name below. We can't use variables
#     # here.
#     bucket = "jdreaver-rules-terraform-test-state"
#     key    = "tf_state_bootstrap"
#     region = "us-west-2"
#   }
# }

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
