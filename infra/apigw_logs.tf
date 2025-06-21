# apigw_logs.tf

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.api.name}"
  retention_in_days = 7
}

resource "aws_iam_role" "apigw_logs" {
  name = "apigw-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apigw_logs" {
  name = "apigw-logs-policy"
  role = aws_iam_role.apigw_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ]
      Resource = "*"
    }]
  })
}

# Adicione os blocos abaixo ao seu aws_api_gateway_stage "prod" (pode ser neste arquivo ou no arquivo original)
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
    format = jsonencode({
      requestId     = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      caller        = "$context.identity.caller"
      user          = "$context.identity.user"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      resourcePath  = "$context.resourcePath"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength= "$context.responseLength"
    })
  }

  method_settings {
    resource_path    = "/*"
    http_method      = "*"
    logging_level    = "INFO"
    data_trace_enabled = true
    metrics_enabled  = true
  }
  
}