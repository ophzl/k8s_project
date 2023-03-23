variable "environment_suffix" {
  type = string
  description = "procure le suffix indiquant l'environnement cible"
}

variable "project_name" {
  type = string
  description = "nom du projet"
}

variable "api_port" {
  type = number
}

variable "access_token_expiry" {
  type = string
}

variable "refresh_token_expiry" {
  type = string
}

variable "refresh_token_cookie_name" {
  type = string
}