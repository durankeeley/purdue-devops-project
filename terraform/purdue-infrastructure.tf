module "infrastructure" {
  source     = "./module"
  allowed_ip = var.allowed_ip
}
