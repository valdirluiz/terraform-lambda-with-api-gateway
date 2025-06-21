terraform {
  backend "s3" {
    bucket         = "lambda-with-api-gateway-terraform-state"
    key            = "lambda-api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}