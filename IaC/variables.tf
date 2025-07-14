variable "api_name" {
  description = "API Name"
  type        = string
  default     = "chatbot-api"
}

variable "user_pool_name" {
  description = "The name for the Cognito User Pool"
  type        = string
  default     = "chatbot-userpool"
}

variable "username" {
  description = "The username for the initial user"
  type        = string
  default     = "kurokood"
}

variable "user_email" {
  description = "The email for the initial user"
  type        = string
  default     = "villarinmon@gmail.com"
}

variable "zone_name" {
  description = "The Route53 zone name"
  type        = string
  default     = "monvillarin.com"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate of monvillarin.com"
  type        = string
  default     = "arn:aws:acm:us-east-1:026045577315:certificate/6f9106a0-d143-4bdb-8d9c-60ec70b4e3ee"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
