# --- Shorten Lambda ---
resource "aws_lambda_function" "shorten" {
  function_name = "url-shortener-shorten"
  filename      = "../lambdas/shorten/shorten.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  # Hash triggers redeployment only when code actually changes
  source_code_hash = filebase64sha256("../lambdas/shorten/shorten.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_shortener.name
      BASE_URL   = "https://short.example.com"  # replace with your domain later
    }
  }
}

# --- Redirect Lambda ---
resource "aws_lambda_function" "redirect" {
  function_name = "url-shortener-redirect"
  filename      = "../lambdas/redirect/redirect.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  source_code_hash = filebase64sha256("../lambdas/redirect/redirect.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.url_shortener.name
    }
  }
}

# --- Analytics Lambda ---
resource "aws_lambda_function" "analytics" {
  function_name = "url-shortener-analytics"
  filename      = "../lambdas/analytics/analytics.zip"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  source_code_hash = filebase64sha256("../lambdas/analytics/analytics.zip")
}

# --- DynamoDB Stream trigger ---
# Fires the analytics Lambda whenever the table is written to
resource "aws_lambda_event_source_mapping" "dynamo_stream" {
  event_source_arn  = aws_dynamodb_table.url_shortener.stream_arn
  function_name     = aws_lambda_function.analytics.arn
  starting_position = "LATEST"      # Only process new events, not historical
  batch_size        = 10            # Process up to 10 records at once
}
