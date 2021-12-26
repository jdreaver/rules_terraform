# local provider
resource "local_file" "hello" {
    content  = "Hello, world!"
    filename = "/tmp/bazel-terraform-demo/hello.txt"
}

# time provider
resource "time_offset" "example" {
  offset_days = 7
}

output "one_week_from_now" {
  value = time_offset.example.rfc3339
}

# TODO: Auto-generating this is necessary or else "terraform init" will try to
# upgrade providers, ignoring the versions we specify in bazel.
terraform {
  # FYI this syntax is ignored for 0.12
  # https://www.terraform.io/language/providers/requirements#v0-12-compatible-provider-requirements
  required_providers {
    local = {
      source  = "registry.terraform.io/hashicorp/local"
      version = "2.1.0"
    }
    time = {
      source  = "registry.terraform.io/hashicorp/time"
      version = "0.7.0"
    }
  }
}
