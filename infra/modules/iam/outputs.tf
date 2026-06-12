output "app_server_role_arn" {
  description = "ARN of the EC2 app server role"
  value       = aws_iam_role.app_server.arn
}

output "app_server_instance_profile_name" {
  description = "Name of the EC2 app server instance profile"
  value       = aws_iam_instance_profile.app_server.name
}

output "job_processor_role_arn" {
  description = "ARN of the Lambda job processor role"
  value       = aws_iam_role.job_processor.arn
}

