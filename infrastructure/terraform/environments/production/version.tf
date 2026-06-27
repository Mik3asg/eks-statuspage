terraform {
  required_version = ">= 1.14"

  # Remote state — S3 stores the state file — using the S3 native state locking (Terraform >= 1.10)
  # No DynoDB needed
  backend "s3" {
    bucket       = "eks-statuspage-terraform-state"
    key          = "production/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}