terraform {
  source = "git::https://${get_env("REPO_DISPATCH_PAT", "")}@github.com/musaumakau/infrastructure-modules.git//kubernetes-addons?ref=kubernetes-addons-v0.1.1"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

locals {
  env            = include.env.locals.env
  aws_region     = "eu-west-1"
  aws_account_id = get_aws_account_id()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-00000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    eks_name                = "demo"
    openid_provider_arn     = "arn:aws:iam::123456789012:oidc-provider"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  cluster_oidc_issuer_url = dependency.eks.outputs.cluster_oidc_issuer_url
  env                     = local.env
  eks_name                = dependency.eks.outputs.eks_name
  openid_provider_arn     = dependency.eks.outputs.openid_provider_arn
  vpc_id                  = dependency.vpc.outputs.vpc_id
  aws_region              = local.aws_region
  aws_account_id          = local.aws_account_id
  skip_helm_deployments   = false

  enable_cluster_autoscaler       = true
  cluster_autoscaler_helm_version = "9.48.0"

  enable_aws_lbc       = true
  aws_lbc_helm_version = "1.7.1"

  enable_ebs_csi_driver = true
  ebs_csi_addon_version = "v1.59.0-eksbuild.1"

  enable_metrics_server       = true
  metrics_server_helm_version = "3.12.1"
  metrics_server_insecure_tls = true

  enable_external_secrets       = true
  external_secrets_helm_version = "0.9.13"

  enable_cert_manager       = true
  cert_manager_helm_version = "v1.14.4"

  enable_external_dns        = true
  external_dns_helm_version  = "1.14.4"
  external_dns_domain_filter = ""

  enable_kube_prometheus_stack       = true
  kube_prometheus_stack_helm_version = "57.2.0"
  grafana_admin_password             = get_env("GRAFANA_ADMIN_PASSWORD", "")

  enable_loki       = true
  loki_helm_version = "2.10.2"

  enable_keda       = true
  keda_helm_version = "2.15.1"
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
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
EOF
}