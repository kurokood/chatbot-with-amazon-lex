variable "domain_name" {
  description = "The domain name for which the certificate should be issued"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

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
}

variable "user_email" {
  description = "The email for the initial user"
  type        = string
}

variable "zone_name" {
  description = "The Route53 hosted zone name"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the domain"
  type        = string
}

variable "lex_bot_alias_id" {
  description = "The ID of the Lex V2 bot alias"
  type        = string
  default     = "prod"
}
