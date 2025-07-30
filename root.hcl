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

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
        region = "eu-west-1"

        assume_role {
            session_name = "test"
            role_arn = "arn:aws:iam::649203810550:role/EksOIDCRole"
        }
    }
    EOF

}