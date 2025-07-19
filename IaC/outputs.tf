output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

output "cognito_client_id" {
  description = "The client ID for the Cognito User Pool app client"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "api_url" {
  description = "The URL of the HTTP API"
  value       = "https://${aws_apigatewayv2_api.http_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_apigatewayv2_stage.http_api_stage.name}"
}

output "cloudfront_distribution_url" {
  description = "URL of the CloudFront distribution to Access your frontend"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}