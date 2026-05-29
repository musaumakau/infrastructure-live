terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//eks?ref=feat/tag-enforcement-module"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  eks_version = "1.33"
  env         = include.env.locals.env
  eks_name    = "demo"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnet_ids

  admin_principal_arns    = ["arn:aws:iam::649203810550:user/Kay"]
  github_actions_role_arn = "arn:aws:iam::649203810550:role/EksOIDCRole"

  node_groups = {
    general = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t4g.xlarge"]
      disk_size      = 20
      ami_type       = "AL2023_ARM_64_STANDARD"
      labels         = {}
      taints         = []
      scaling_config = {
        desired_size = 1
        max_size     = 2
        min_size     = 0
      }
    }
  }

  # Tag module inputs
  project     = "infrastructure-modules"
  environment = lower(include.env.locals.env)
  owner       = "engineering"
  cost_center = "CC-0001"
}