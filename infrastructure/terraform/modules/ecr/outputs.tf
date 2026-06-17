# repository_urls — consumed by CI/CD to know where to push images
# e.g. 123456789.dkr.ecr.eu-west-1.amazonaws.com/eks-statuspage/backend

output "repository_urls" {
  description = "Map of app name to ECR repository URL — used by CI/CD to push images"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of app name to ECR repository ARN — used for IAM policy grants"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}
