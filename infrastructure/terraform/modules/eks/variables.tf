variable "project_name" {
  description = "Project name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Max number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired number of node in the node group"
  type        = number
  default     = 2

}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}