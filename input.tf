variable "network" {
  type        = "string"
  description = "The network address space that the VPC will be created in."
  default     = "10.0.0.0/16"
}

variable "name" {
  type        = "string"
  description = "The name of the cluster being created in AWS."
  default     = "valhalla"
}

variable "environment" {
  type        = "string"
  description = "The name of the environment stage being deployed to."
  default     = "sandbox"
}

variable "instance-sizes" {
  type        = "list"
  description = "Which instance sizes should be created for this cluster?"

  default = [
    "t2.medium",
  ]
}
