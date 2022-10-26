module "labels" {
  source  = "skyfjell/label/null"
  version = "1.0.3"

  tenant      = "tf"
  environment = "test"
}

module "backend" {
  source = "../../"

  labels = module.labels

  config_users = {
    arns = ["arn:aws:iam:::user/tf-test"]
  }
}
