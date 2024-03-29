
terraform {



  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }

  }

  required_version = "~> 1.7.0"


  # backend "s3" {
  #   bucket = "ic-terraform-states"
  #   key    = "ic-challenge/terraform.tfstate"
  #   region = "us-east-2"
  #   encrypt = true
  # }  
}

