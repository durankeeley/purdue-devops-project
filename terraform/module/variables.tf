variable "allowed_ip" {
  description = "IP address allowed to access the Jenkins server"
  type        = string
  sensitive   = true
}

variable "jenkins_admin_password" {
  description = "An optional pre-defined password for the Jenkins admin user. If null, a random password will be generated."
  type        = string
  default     = null
  sensitive   = true
}