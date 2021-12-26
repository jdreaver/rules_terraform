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
