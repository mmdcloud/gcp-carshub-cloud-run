# Creating a Serverless VPC connector
resource "google_vpc_access_connector" "connector" {
  name          = var.name
  ip_cidr_range = var.ip_cidr_range
  network       = var.network_name
  min_instances = var.min_instances
  max_instances = var.max_instances
  machine_type  = var.machine_type
}