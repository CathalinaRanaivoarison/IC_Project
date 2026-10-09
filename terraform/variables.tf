variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "admin_ip" {
  description = "Public IP address authorized to access the infrastructure"
  type        = string
}