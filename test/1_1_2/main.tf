# local provider
resource "local_file" "hello" {
  content  = "Hello, world!"
  filename = "/tmp/bazel-terraform-demo/hello.txt"
}

module "time" {
  source = "../time_module"
}
