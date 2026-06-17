provider "aws" {
  region = var.aws_region
}

# API token is read from CLOUDFLARE_API_TOKEN env var — never hardcoded
provider "cloudflare" {}