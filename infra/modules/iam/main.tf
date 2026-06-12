locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "app_server" {
  name = "${local.name_prefix}-app-server-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "app_server" {
  name = "${local.name_prefix}-app-server-policy"
  tags = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_server" {
  role       = aws_iam_role.app_server.name
  policy_arn = aws_iam_policy.app_server.arn
}

resource "aws_iam_instance_profile" "app_server" {
  name = "${local.name_prefix}-app-server-profile"
  role = aws_iam_role.app_server.name
  tags = local.tags
}

# Job processor (Lambda) role + policy
resource "aws_iam_role" "job_processor" {
  name = "${local.name_prefix}-job-processor-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "job_processor" {
  name = "${local.name_prefix}-job-processor-policy"
  tags = local.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsume"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [var.sqs_queue_arn]
      },
      {
        Sid      = "S3WriteResults"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${var.s3_bucket_arn}/results/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "job_processor" {
  role       = aws_iam_role.job_processor.name
  policy_arn = aws_iam_policy.job_processor.arn
}