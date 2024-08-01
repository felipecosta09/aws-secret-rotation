# AWS region variable to be used in the provider block
variable "aws_region" {
  description = "AWS region"
  type = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^([a-z]{2}-[a-z]+-[1-9])$", var.aws_region))
    error_message = "Invalid AWS region. Please provide a valid AWS region in the format: xx-xxxxx-x (e.g., us-east-1)."
  }
}

# API key variable to be used in the secret manager
variable "apikey" {
  type = string
  description = "My API key"
  sensitive = true
  default = "AIzaSyDaGmWKa4JsXZ-HjGw7ISLn_3namBGewQe"
}
