# local provider
resource "local_file" "hello" {
    content  = "Hello, world!"
    filename = "/tmp/bazel-terraform-demo/hello.txt"
}

module "time" {
  source = "../time_module"
}

# TODO: Auto-generating this is necessary or else "terraform init" will try to
# upgrade providers, ignoring the versions we specify in bazel.
terraform {
  required_providers {
    local = {
      source  = "registry.terraform.io/hashicorp/local"
      version = "2.1.0"
    }
  }
}
