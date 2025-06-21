provider "aws" {
  region = "us-east-1"
}

# Bucket para o código da Lambda
resource "aws_s3_bucket" "lambda_code" {
  bucket = "lambda-with-api-gateway-code"
  force_destroy = true
}

# Upload do zip da Lambda
resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_code.id
  key    = "lambda.zip"
  source = "${path.module}/lambda.zip"
  etag   = filemd5("${path.module}/lambda.zip")
}

# IAM Role para Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-with-api-gateway-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "api_lambda" {
  function_name = "api-lambda"
  s3_bucket     = aws_s3_bucket.lambda_code.id
  s3_key        = aws_s3_bucket_object.lambda_zip.key
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
}

# API Gateway REST
resource "aws_api_gateway_rest_api" "api" {
  name        = "lambda-api"
  description = "API Gateway para Lambda"
}

resource "aws_api_gateway_resource" "hello_word" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello-word"
}

resource "aws_api_gateway_method" "hello_word" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}