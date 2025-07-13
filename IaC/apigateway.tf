resource "aws_apigatewayv2_route" "get_meetings_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /meetings"
  target    = "integrations/${aws_apigatewayv2_integration.get_meetings_integration.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "get_meetings_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_meetings_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "get_pending_meetings_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /pending"
  target    = "integrations/${aws_apigatewayv2_integration.get_pending_meetings_integration.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "get_pending_meetings_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_pending_meetings_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "put_status_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /status"
  target    = "integrations/${aws_apigatewayv2_integration.put_meeting_status_integration.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_authorizer.id
}

resource "aws_apigatewayv2_integration" "put_meeting_status_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.change_meeting_status_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "chatbot_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /chatbot"
  target    = "integrations/${aws_apigatewayv2_integration.chatbot_integration.id}"
}

resource "aws_apigatewayv2_integration" "chatbot_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.chatbot_lambda.invoke_arn
}
