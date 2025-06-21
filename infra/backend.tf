terraform {
  backend "s3" {
    bucket         = "terraform-state-lambda-with-api-gateway"
    key            = "lambda-api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}