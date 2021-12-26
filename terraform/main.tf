# TODO: Uncomment when implementing providers (this is the hashicorp/local provider)
# resource "local_file" "hello" {
#     content  = "Hello, world!"
#     filename = "/tmp/bazel-terraform-demo/hello.txt"
# }

output "hello_world" {
  value = "Hello, World!"
}
