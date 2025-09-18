terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//kubernetes-addons?ref=kubernetes-addons-v0.0.2"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    eks_name                = "demo"
    openid_provider_arn     = "arn:aws:iam::123456789012:oidc-provider"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "apply"]
}

inputs = {
  env                             = include.env.locals.env
  eks_name                        = dependency.eks.outputs.eks_name
  openid_provider_arn             = dependency.eks.outputs.openid_provider_arn
  cluster_oidc_issuer_url         = dependency.eks.outputs.cluster_oidc_issuer_url
  enable_cluster_autoscaler       = true
  cluster_autoscaler_helm_version = "9.48.0"
}

generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster" "eks" {
  name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
EOF
}