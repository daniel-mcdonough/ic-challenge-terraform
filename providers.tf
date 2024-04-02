
terraform {



  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
  }

  required_version = "~> 1.7.0"


  # backend "s3" {
  #   bucket = "daniel-intercax"
  #   key    = "ic-challenge-postgres/terraform.tfstate"
  #   region = "us-east-2"
  #   encrypt = true
  # }  
}

# Change these to your Kubernetes config
provider "kubernetes" {
      config_path = "~/.k3s/k3s-kubeconfig.yaml"
      config_context = "default"
    }

provider "helm" {
  kubernetes {
    config_path = "~/.k3s/k3s-kubeconfig.yaml"
  }

}