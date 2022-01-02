# Generates a .tf.json file for a Terraform backend configuration. You cannot use
# variables in backend blocks in Terraform
# (https://github.com/hashicorp/terraform/issues/13022), so we have to reify the
# entire block as a literal.
#
# This can be run like this:
#
# $ jsonnet --tla-str backend_type=s3 \
#           --tla-code-file backend_config=s3_backend_config.json

function(backend_type, backend_config) {
  terraform: {
    [backend_type]: backend_config
  }
}
