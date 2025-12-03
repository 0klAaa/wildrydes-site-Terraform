########################################
# VARIABLES D'ENTRÉE
########################################

variable "aws_region" {
  description = "Région AWS utilisée pour le déploiement"
  type        = string
  default     = "eu-west-1" # Promis j'écoute Matthieu :p
}

variable "github_repo" {
  description = "URL HTTPS du repo GitHub"
  type        = string
  default =  "https://github.com/0klAaa/wildrydes-site-Terraform.git"
}

variable "github_access_token" {
  description = "Token GitHub utilisé par Amplify pour lire le repo"
  type        = string
  sensitive   = true
}
