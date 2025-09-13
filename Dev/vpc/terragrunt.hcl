terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//vpc?ref=vpc-v0.0.2"
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
  env                  = include.env.locals.env
  azs                  = ["eu-west-1a", "eu-west-1b"]
  private_subnet_cidrs = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnet_cidrs  = ["10.0.64.0/19", "10.0.96.0/19"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/Dev"       = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"    = 1
    "kubernetes.io/cluster/Dev" = "owned"
  }
}