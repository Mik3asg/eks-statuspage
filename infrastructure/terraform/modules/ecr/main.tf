# ECR Module — resource map
#
# aws_ecr_repository      — private container registry, one per app (frontend, backend)
# aws_ecr_lifecycle_policy — auto-deletes old images, keeps only the last N per repo (cost control)
#
# CI/CD pushes images here → EKS pulls them at deploy time

locals {
  repos = ["frontend", "backend"]
}

# for_each creates one repository per app — keyed by name so each is managed independently
resource "aws_ecr_repository" "this" {
  for_each = toset(local.repos)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    # Scans every pushed image for known CVEs — free, no reason to disable
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-${each.value}"
    Project = var.project_name
  }
}

# Deletes untagged images immediately and keeps only the last N tagged images
# Prevents unbounded storage growth — each CI run pushes a new image
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images immediately"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.image_retention_count} tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = { type = "expire" }
      }
    ]
  })
}
