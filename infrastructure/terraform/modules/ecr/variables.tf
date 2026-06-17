variable "project_name" {
  description = "Project name — used to prefix repository names"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to keep per repository — older ones are deleted automatically"
  type        = number
  default     = 10
}
