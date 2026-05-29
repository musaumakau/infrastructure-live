terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//eks?ref=eks-v0.0.3"
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
  eks_name    = "demo-prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnet_ids

  admin_principal_arns    = ["arn:aws:iam::649203810550:user/Kay"]
  github_actions_role_arn = "arn:aws:iam::649203810550:role/EksOIDCRole"

  node_groups = {
    general = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      disk_size      = 50
      ami_type       = "AL2023_ARM_64_STANDARD"
      labels         = {}
      taints         = {}
      scaling_config = {
        # Prod runs HA — minimum 2 nodes across AZs at all times
        desired_size = 2
        max_size     = 5
        min_size     = 2
      }
    }
  }
}
