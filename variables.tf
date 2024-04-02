# variable "zone" {
#   description = "The domain you want to use"
#   type = string
# }

variable "state_bucket" {
  description = "The bucket for your terraform state"
  type = string
}

variable "state_key" {
  description = "Terraform state key"
  type = string
  default = "base-state/terraform.tfstate"
}

variable "postgres_password" {
  description = "postgres password"
  type = string
  sensitive = true
}

