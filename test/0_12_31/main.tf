# local provider
resource "local_file" "hello" {
  content  = "Hello, world!"
  filename = "/tmp/rules_terraform/hello.txt"
}

module "time" {
  source = "../time_module"
}
