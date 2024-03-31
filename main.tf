module "k8s_main_sg" {
  source     = "git::https://github.com/agmtr/terraform-yandex-sg.git?ref=v1.0.0"
  name       = "k8s-cluster-sg"
  network_id = var.network.id
  enable_default_rules = {
    egress_any      = true
    self_sg         = true
    lb_healthchecks = true
  }
  rules = {
    pods-services = {
      direction = "ingress"
      v4_cidr_blocks = [
        var.network.cluster_ip_range,
        var.network.service_ip_range
      ]
    }
  }
}

module "k8s_api_sg" {
  source     = "git::https://github.com/agmtr/terraform-yandex-sg.git?ref=v1.0.0"
  name       = "k8s-api-sg"
  network_id = var.network.id
  rules = {
    api-443 = {
      direction      = "ingress"
      port           = 443
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
    api-6443 = {
      direction      = "ingress"
      port           = 6443
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

module "k8s_ng_ssh_sg" {
  source     = "git::https://github.com/agmtr/terraform-yandex-sg.git?ref=v1.0.0"
  name       = "k8s-ng-ssh-sg"
  network_id = var.network.id
  enable_default_rules = {
    ssh = true
  }
}

module "k8s_ng_nodeports_sg" {
  source     = "git::https://github.com/agmtr/terraform-yandex-sg.git?ref=v1.0.0"
  name       = "k8s-ng-nodeports-sg"
  network_id = var.network.id
  rules = {
    nodeports = {
      direction      = "ingress"
      protocol       = "TCP"
      from_port      = 30000
      to_port        = 32767
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

module "k8s_cluster" {
  source    = "git::https://github.com/agmtr/terraform-yandex-k8s-master.git?ref=v1.0.2"
  folder_id = var.folder_id
  name = var.name
  network = {
    id               = var.network.id
    cluster_ip_range = var.network.cluster_ip_range
    service_ip_range = var.network.service_ip_range
    security_group_ids = [
      module.k8s_main_sg.id,
      module.k8s_api_sg.id
    ]
    public_ip = var.network.public_ip
  }
  location = var.location
  maintenance_policy = {
    auto_upgrade = var.maintenance_policy.auto_upgrade
    day = var.maintenance_policy.day
    duration = var.maintenance_policy.duration
    start_time = var.maintenance_policy.start_time
  }
  config = {
    version         = var.config.version
    release_channel = var.config.release_channel
    kms_key_id      = var.config.kms_key_id
  }
}

module "k8s_ng" {
  for_each = var.nodegroups

  source     = "git::https://github.com/agmtr/terraform-yandex-k8s-ng?ref=v1.0.0"
  cluster_id = module.k8s_cluster.id
  network = {
    subnets = each.value.subnets
    public_ip = var.network.public_ip
    security_group_ids = [
      module.k8s_main_sg.id,
      module.k8s_ng_ssh_sg.id,
      module.k8s_ng_nodeports_sg.id
    ]
  }
  scale_policy = {
    fixed = {
      size = length(each.value.subnets)
    }
  }
  resources = each.value.resources
  maintenance_policy = {
    auto_upgrade = var.maintenance_policy.auto_upgrade
    day = var.maintenance_policy.day
    duration = var.maintenance_policy.duration
    start_time = var.maintenance_policy.start_time
  }
  config = {
    version = var.config.ng_version != null ? var.config.ng_version : var.config.version
    container_runtime = var.config.container_runtime
  }
}
