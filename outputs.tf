output "master_id" {
  value = module.k8s_cluster.id
}

output "nodegroups_ids" {
  value = {for k,v in module.k8s_ng: k => v.id}
}
