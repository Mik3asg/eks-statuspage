variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR block for public subnet"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR block for private subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
}