output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_info" {
  value = google_compute_subnetwork.subnet[*]
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "self_link" {
  value = google_compute_network.vpc.self_link
}

output "vpc_connectors" {
  value = google_vpc_access_connector.connector[*]
}