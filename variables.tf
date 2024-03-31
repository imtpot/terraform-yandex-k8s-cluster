variable "folder_id" {
  type = string
}

variable "name" {
  type = string
  default = ""
}

variable "network" {
  type = object({
    id               = string
    public_ip        = optional(bool, true)
    cluster_ip_range = optional(string, "10.112.0.0/16")
    service_ip_range = optional(string, "10.96.0.0/16")
  })
}

variable "location" {
  type = object({
    region = optional(string)
    zone   = optional(string)
  })
  default = {
    zone = "ru-central1-a"
  }
}

variable "config" {
  type = object({
    version         = optional(string)
    ng_version      = optional(string)
    release_channel = optional(string)
    kms_key_id      = optional(string)
    container_runtime = optional(string)
  })
  default = {}
}

variable "nodegroups" {
  type = map(object({
    subnets = map(object({
      id   = string
      zone = string
    }))
    resources = optional(object({
      cores         = number
      memory        = number
      core_fraction = optional(number, 100)
      preemptible   = optional(bool, false)
    }))
    public_ip       = optional(bool, false)
  }))
}

variable "maintenance_policy" {
  type = object({
    auto_upgrade = optional(bool, true)
    day          = optional(string)
    start_time   = optional(string)
    duration     = optional(string)
  })
  default = {}
}
