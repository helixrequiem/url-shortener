variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "dynamo_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "UrlShortener"
}
