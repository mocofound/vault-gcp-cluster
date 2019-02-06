output "cluster_tag_name" {
  value = "${var.cluster_name}"
}

output "instance_group_id" {
  value = "${google_compute_region_instance_group_manager.vault.id}"
}

output external_ip {
  description = "The external ip address of the forwarding rule."
  value       = "${google_compute_forwarding_rule.default.ip_address}"
}


output "instance_group_url" {
  value = "${google_compute_region_instance_group_manager.vault.self_link}"
}


output "firewall_rule_allow_intracluster_vault_url" {
  value = "${google_compute_firewall.allow_intracluster_vault_consul.self_link}"
}

output "firewall_rule_allow_intracluster_vault_id" {
  value = "${google_compute_firewall.allow_intracluster_vault_consul.id}"
}

output "firewall_rule_allow_inbound_api_url" {
  value = "${google_compute_firewall.allow_inbound_api.*.self_link}"
}

output "firewall_rule_allow_inbound_api_id" {
  value = "${google_compute_firewall.allow_inbound_api.*.id}"
}

output "firewall_rule_allow_inbound_health_check_url" {
  value = "${element(concat(google_compute_firewall.allow_inbound_health_check.*.self_link, list("")), 0)}"
}

output "firewall_rule_allow_inbound_health_check_id" {
  value = "${element(concat(google_compute_firewall.allow_inbound_health_check.*.id, list("")), 0)}"
}
