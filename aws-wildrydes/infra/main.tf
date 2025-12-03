########################################
# PROVIDER AWS
########################################

provider "aws" {
  region = var.aws_region
}

########################################
# AMPLIFY : HÉBERGEMENT DU SITE (GIT > AMPLIFY)
########################################

resource "aws_amplify_app" "wildrydes" {
  name         = "wildrydes-site"
  repository   = var.github_repo
  access_token = var.github_access_token

  environment_variables = {
    ENV = "prod"
  }
}

resource "aws_amplify_branch" "main" {
  app_id           = aws_amplify_app.wildrydes.id
  branch_name      = "main"
  stage            = "PRODUCTION"
  enable_auto_build = true
}

########################################
# COGNITO : USER POOL + CLIENT WEB
########################################

resource "aws_cognito_user_pool" "wildrydes" {
  name = "WildRydes"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  password_policy {
    minimum_length    = 8
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "web_app" {
  name         = "WildRydesWebApp"
  user_pool_id = aws_cognito_user_pool.wildrydes.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}

########################################
# DYNAMODB : TABLE Rides
########################################

resource "aws_dynamodb_table" "rides" {
  name         = "Rides"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "RideId"

  attribute {
    name = "RideId"
    type = "S"
  }
}

########################################
# IAM : RÔLE LAMBDA + POLITIQUES
########################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "wildrydes_lambda" {
  name               = "WildRydesLambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.wildrydes_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_write_access" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.rides.arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_write_access" {
  name   = "DynamoDBWriteAccess"
  role   = aws_iam_role.wildrydes_lambda.id
  policy = data.aws_iam_policy_document.dynamodb_write_access.json
}

########################################
# LAMBDA : RequestUnicorn
########################################

resource "aws_lambda_function" "request_unicorn" {
  function_name = "RequestUnicorn"
  role          = aws_iam_role.wildrydes_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"

  filename         = "${path.module}/lambda/requestUnicorn.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/requestUnicorn.zip")

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      RIDES_TABLE_NAME = aws_dynamodb_table.rides.name
    }
  }
}

########################################
# API GATEWAY REST + AUTHORIZER COGNITO
########################################

resource "aws_api_gateway_rest_api" "wildrydes" {
  name        = "WildRydes"
  description = "WildRydes REST API"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource "aws_api_gateway_authorizer" "wildrydes" {
  name          = "WildRydes"
  rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.wildrydes.arn]

  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "ride" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  parent_id   = aws_api_gateway_rest_api.wildrydes.root_resource_id
  path_part   = "ride"
}

resource "aws_api_gateway_method" "post_ride" {
  rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
  resource_id   = aws_api_gateway_resource.ride.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.wildrydes.id
}

resource "aws_api_gateway_integration" "post_ride_lambda" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  resource_id = aws_api_gateway_resource.ride.id
  http_method = aws_api_gateway_method.post_ride.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.request_unicorn.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_unicorn.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.wildrydes.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    aws_api_gateway_integration.post_ride_lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  description  = "prod"
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
  deployment_id = aws_api_gateway_deployment.prod.id
  stage_name    = "prod"
}
