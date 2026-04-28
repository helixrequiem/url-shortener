# The trust policy — allows Lambda service to assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The role both Lambda functions will use
resource "aws_iam_role" "lambda_exec" {
  name               = "url-shortener-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Allow Lambdas to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambdas only the exact DynamoDB actions they need — nothing more
resource "aws_iam_policy" "lambda_dynamo" {
  name = "url-shortener-lambda-dynamo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",      # shorten: write new URL
        "dynamodb:GetItem",      # redirect: read URL
        "dynamodb:UpdateItem",   # redirect: increment clicks
        "dynamodb:Query"         # future: list URLs by user
      ]
      Resource = [
        aws_dynamodb_table.url_shortener.arn,
        "${aws_dynamodb_table.url_shortener.arn}/index/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamo.arn
}

# Allow the analytics Lambda to read from the DynamoDB stream
resource "aws_iam_policy" "lambda_stream" {
  name = "url-shortener-lambda-stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams"
      ]
      Resource = "${aws_dynamodb_table.url_shortener.stream_arn}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_stream_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_stream.arn
}
