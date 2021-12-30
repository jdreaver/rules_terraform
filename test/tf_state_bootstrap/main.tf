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
# $ terraform apply
# (uncomment this block)
# $ terraform init
# $ terraform apply
#
terraform {
  backend "s3" {
    # N.B. Make sure S3 bucket and DynamoDB names match names below. We can't
    # use variables in backend blocks (see
    # https://github.com/hashicorp/terraform/issues/13022)
    #
    # TODO: How can we share this variable with bazel? It would be nice to
    # define it once and use it in all of our roots. Maybe this backend block
    # should be generated with bazel, which would allow us to reference the
    # bucket and DDB table as variables and perhaps assert that all backends use
    # a unique key in some higher level integration test.
    bucket         = "jdreaver-rules-terraform-test-state"
    key            = "tf_state_bootstrap"
    region         = "us-west-2"
    dynamodb_table = "terraform-statelock"
  }
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
