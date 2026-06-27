output "cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_urls" {
  description = "ECR URLs for frontend and backend — used by CI/CD to push images"
  value       = module.ecr.repository_urls
}

output "irsa_backend_role_arn" {
  description = "IAM role ARN for the backend service account"
  value       = module.irsa_backend.role_arn
}

output "irsa_frontend_role_arn" {
  description = "IAM role ARN for the frontend service account"
  value       = module.irsa_frontend.role_arn
}

output "irsa_ebs_csi_role_arn" {
  description = "IAM role ARN for the EBS CSI driver"
  value       = module.irsa_ebs_csi.role_arn
}
