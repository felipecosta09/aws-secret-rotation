# This example generates a random string of 8 characters
resource "random_string" "random" {
  length           = 8
  upper            = false
  special          = false
  override_special = "/@£$"
}

# Get the AWS Account ID
data "aws_caller_identity" "current" {}