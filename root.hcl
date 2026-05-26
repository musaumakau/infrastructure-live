
remote_state {
  backend = "s3"
  generate = {
    path      = "state.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "tf-backennd-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

