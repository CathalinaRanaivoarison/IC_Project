variable "aws_region" {
  type        = string
  default     = "eu-west-3" # Région Paris
}

variable "instance_ami" {
  type        = string
  default     = "ami-007fae589fdf6e955" # Ubuntu 22.04 LTS à Paris 
}

variable "ssh_key_name" {
  type        = string
  description = "Le nom de votre clé SSH existante sur votre console AWS"
  default     = "ma-cle-aws" 
}

