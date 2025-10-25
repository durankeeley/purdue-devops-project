module "infrastructure" {
  source     = "./module"
  allowed_ip = var.allowed_ip
  region = "ap-southeast-2"
}
