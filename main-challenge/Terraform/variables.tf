variable "net" {
  type = map(string)
  default = {
    cidr = "10.0.0.0/16"
  }
}

variable "GITLAB_URL" {
  type        = string
  description = "The GitLab base url. Supplied by shell env. (TF_VAR_)"
}

variable "REGISTRATION_TOKEN" {
  type        = string
  description = "Token to register runners. Supplied by shell env. (TF_VAR_)"
}