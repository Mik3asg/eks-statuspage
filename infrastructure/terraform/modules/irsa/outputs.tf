# What the root module (environments/production) needs from IRSA:
# - role_arn        → annotated onto the Kubernetes service account so pods can assume it
# - oidc_provider_arn → may be reused by other IRSA module calls for the same cluster

output "role_arn" {
  description = "ARN of the IAM role — annotate this onto the Kubernetes service account"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role — useful for attaching additional policies outside this module"
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider — passed through from eks/ for convenience"
  value       = var.oidc_provider_arn
}
