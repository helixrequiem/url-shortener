output "dynamodb_table_name" {
  value = aws_dynamodb_table.url_shortener.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.url_shortener.arn
}

output "shorten_lambda_arn" {
  value = aws_lambda_function.shorten.arn
}

output "redirect_lambda_arn" {
  value = aws_lambda_function.redirect.arn
}

output "analytics_lambda_arn" {
  value = aws_lambda_function.analytics.arn
}

output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}
