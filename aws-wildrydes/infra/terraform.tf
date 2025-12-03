########################################
# CONFIG GLOBALE TERRAFORM
########################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend distant (optionnel, à activer plus tard si tu veux)
  # backend "s3" {
  #   bucket         = "okla-bucket-terraform-state"
  #   key            = "wildrydes/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "terraform-locks"
  # }
}