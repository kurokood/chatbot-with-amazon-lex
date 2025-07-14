variable "api_name" {
  description = "API Name"
  type        = string
  default     = "meety-api"
}

variable "user_pool_name" {
  description = "The name for the Cognito User Pool"
  type        = string
  default     = "chapter7-userpool"
}

variable "username" {
  description = "The username for the initial user"
  type        = string
}

variable "user_email" {
  description = "The email for the initial user"
  type        = string
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}