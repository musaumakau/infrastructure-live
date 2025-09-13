terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//eks?ref=eks-v0.0.2"
}


include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  eks_version = "1.33"
  env         = include.env.locals.env
  eks_name    = "demo"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnet_ids



  node_groups = {
    general = {
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3a.xlarge"]
      scaling_config = {
        desired_size = 1
        max_size     = 2
        min_size     = 0
        disk_size     = 20
      }
    }

  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-1234", "subnet-5678"]
  }
}
