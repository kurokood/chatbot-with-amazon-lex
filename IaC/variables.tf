variable "api_name" {
  description = "API Name"
  type        = string
  default     = "meety-api"
}

variable "user_pool_name" {
  description = "The name for the Cognito User Pool"
  type        = string
  default     = "meety-userpool"
}

variable "username" {
  description = "The username for the initial user"
  type        = string
  default = "kurokood"
}

variable "user_email" {
  description = "The email for the initial user"
  type        = string
  default = "villarinmon@gmail.com"
}

variable "zone_name" {
  description = "The Route53 hosted zone name"
  type        = string
  default     = "monvillarin.com"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the domain"
  type        = string
  default     = "arn:aws:acm:us-east-1:026045577315:certificate/6f9106a0-d143-4bdb-8d9c-60ec70b4e3ee"
}

# Lex bot configuration
variable "lex_bot_id" {
  description = "The ID of the Lex V2 bot"
  type        = string
  default     = "XXXXXXXXXX" # Replace with your actual Bot ID
}

variable "lex_bot_alias_id" {
  description = "The ID of the Lex V2 bot alias"
  type        = string
  default     = "XXXXXXXXXX" # Replace with your actual Bot Alias ID
}

# Data sources are defined in s3-cloudfront.tf
# data "aws_region" "current" {} - already defined in s3-cloudfront.tf
# data "aws_caller_identity" "current" {} - already defined in s3-cloudfront.tf
