variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the application S3 bucket"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue consumed by the async worker"
}