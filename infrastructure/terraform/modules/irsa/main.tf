# IRSA (IAM Roles for Service Accounts) — resource map
#
# aws_iam_role.this              — IAM role scoped to one specific Kubernetes service account via OIDC condition
# aws_iam_role_policy_attachment — attaches AWS-managed policies to the role (one resource per ARN)
# aws_iam_role_policy.inline     — attaches a custom inline policy when managed policies aren't granular enough
#
# The OIDC provider is NOT created here — it lives in the eks/ module (one provider per cluster).
# var.oidc_provider_arn is passed in from eks/ so this module can be called multiple times safely.

# IAM role a pod can assume — the Condition block is critical:
# without it any pod in the cluster could assume this role, defeating the purpose of IRSA
resource "aws_iam_role" "this" {
  name = "${var.cluster_name}-${var.service_account_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })
}

# Attaches one AWS-managed policy per ARN supplied by the caller (environments/production decides what permissions each pod needs)
# toset() keys each ARN as a unique identifier — for_each creates one resource per ARN, each.value is the current ARN
# vs count: removing one ARN with count shifts indexes and destroys the wrong resources; for_each only touches the removed one
resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.policy_arns)
  policy_arn = each.value
  role       = aws_iam_role.this.name
}

# Only created when var.inline_policy_json is provided — use for fine-grained custom permissions
resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json != null ? 1 : 0
  name   = "${var.cluster_name}-${var.service_account_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
