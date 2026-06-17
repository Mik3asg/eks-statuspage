# environments/production — root module
#
# Wires all modules together in dependency order:
#   vpc → eks → irsa (x2)
#              → ecr
#
# ADR: DNS managed by ExternalDNS (Helm) not Terraform — auto-syncs Cloudflare from Ingress annotations.
#
# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# -----------------------------------------------------------------------------
# EKS cluster + OIDC provider
# -----------------------------------------------------------------------------

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_desired_size  = var.node_desired_size
}

# -----------------------------------------------------------------------------
# IRSA — one role per service account
# -----------------------------------------------------------------------------

module "irsa_backend" {
  source = "../../modules/irsa"

  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn
  namespace               = "production"
  service_account_name    = "backend"
  policy_arns             = [] # add e.g. AmazonS3ReadOnlyAccess when needed
}

module "irsa_frontend" {
  source = "../../modules/irsa"

  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn
  namespace               = "production"
  service_account_name    = "frontend"
  policy_arns             = []
}

# -----------------------------------------------------------------------------
# ECR — container registries for frontend and backend images
# -----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
}

