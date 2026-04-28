# -----------------------------------------------
# Log Groups
# -----------------------------------------------

resource "aws_cloudwatch_log_group" "shorten_logs" {
  name              = "/aws/lambda/url-shortener-shorten"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "redirect_logs" {
  name              = "/aws/lambda/url-shortener-redirect"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "analytics_logs" {
  name              = "/aws/lambda/url-shortener-analytics"
  retention_in_days = 14
}

# -----------------------------------------------
# Metric Filter
# -----------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "click_events" {
  name           = "ClickEventCount"
  log_group_name = aws_cloudwatch_log_group.analytics_logs.name
  pattern        = "{ $.type = \"CLICK_EVENT\" }"

  metric_transformation {
    name      = "ClickCount"
    namespace = "UrlShortener"
    value     = "1"
    unit      = "Count"
  }
}

# -----------------------------------------------
# Alarms
# -----------------------------------------------

resource "aws_cloudwatch_metric_alarm" "shorten_errors" {
  alarm_name          = "url-shortener-shorten-errors"
  alarm_description   = "Shorten Lambda is throwing errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = "url-shortener-shorten" }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "redirect_errors" {
  alarm_name          = "url-shortener-redirect-errors"
  alarm_description   = "Redirect Lambda is throwing errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = "url-shortener-redirect" }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "redirect_latency" {
  alarm_name          = "url-shortener-redirect-high-latency"
  alarm_description   = "Redirect Lambda p99 latency exceeded 3 seconds"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  dimensions          = { FunctionName = "url-shortener-redirect" }
  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 1
  threshold           = 3000
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "url-shortener-api-5xx"
  alarm_description   = "API Gateway is returning 5xx errors"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  dimensions = {
    ApiId = aws_apigatewayv2_api.main.id
  }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

# -----------------------------------------------
# Dashboard
# -----------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "url-shortener"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# URL Shortener — Live Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "Clicks (last 1h)"
          view    = "timeSeries"
          region  = "ap-south-1"
          period  = 60
          stat    = "Sum"
          metrics = [
            ["UrlShortener", "ClickCount"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Shorten — Invocations & Errors"
          view   = "timeSeries"
          region = "ap-south-1"
          period = 60
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "url-shortener-shorten", { stat = "Sum", label = "Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", "url-shortener-shorten", { stat = "Sum", label = "Errors", color = "#d62728" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Redirect — Invocations & Errors"
          view   = "timeSeries"
          region = "ap-south-1"
          period = 60
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "url-shortener-redirect", { stat = "Sum", label = "Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", "url-shortener-redirect", { stat = "Sum", label = "Errors", color = "#d62728" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Redirect — Latency (p50 / p99)"
          view   = "timeSeries"
          region = "ap-south-1"
          period = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "url-shortener-redirect", { stat = "p50", label = "p50" }],
            ["AWS/Lambda", "Duration", "FunctionName", "url-shortener-redirect", { stat = "p99", label = "p99", color = "#ff7f0e" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway — 4xx / 5xx Errors"
          view   = "timeSeries"
          region = "ap-south-1"
          period = 60
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", aws_apigatewayv2_api.main.id, { stat = "Sum", label = "4xx", color = "#ff7f0e" }],
            ["AWS/ApiGateway", "5XXError", "ApiId", aws_apigatewayv2_api.main.id, { stat = "Sum", label = "5xx", color = "#d62728" }]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 13
        width  = 24
        height = 3
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.shorten_errors.arn,
            aws_cloudwatch_metric_alarm.redirect_errors.arn,
            aws_cloudwatch_metric_alarm.redirect_latency.arn,
            aws_cloudwatch_metric_alarm.api_5xx.arn,
          ]
        }
      }
    ]
  })
}
