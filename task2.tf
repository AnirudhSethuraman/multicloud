provider “kubernetes” {
 config_context_cluster = “minikube”
}//AWS provider credentials
provider "aws" {
  region     = "ap-south-1"
  profile    = "cloud"
}//Database instance
resource "aws_db_instance" "mysqldb" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  storage_type         = "gp2"
  name                 = "mydb"
  username             = "tester"
  password             = "helloworld"
  port                 = "3306"
  publicly_accessible  = true
  skip_final_snapshot  = true
  parameter_group_name = "default.mysql5.7"tags = {
    Name = "Wp-database"
  }
}//Creating a deployment resource for our application
resource “kubernetes_deployment” “example” {
 metadata {
 name = “wordpressdeployment”
 labels = {
 test = “hello”
 }
 }spec {
 replicas = 3selector {
 match_labels = {
 test = “hello”
 }
 }template {
 metadata {
 labels = {
 test = “hello”
 }
 }spec {
 container {
 image = “wordpress:4.8-apache”
 name = “wordpresscontainer”}
 }
 }
 }
}//creating a service, to expose our application to outside world
resource “kubernetes_service” “wp-expose” {
 metadata {
 name = “terraform-wp-service”
 }
 spec {
 selector = {
 test = “hello”
 }
 //valid ports range from:30000-32767
 port {
 node_port = 32765
 port = 80
 target_port = 80
 }type = “NodePort”
 }
}


____________________________________________________________

provider “aws” {
 region = “ap-south-1”
 profile = “cloud”
}//Database instance
resource “aws_db_instance” “mysqldb” {
 allocated_storage = 10
 engine = “mysql”
 engine_version = “5.7”
 instance_class = “db.t2.micro”
 storage_type = “gp2”
 name = “mydb”
 username = “tester”
 password = “longpassword”
 port = “3306”
 publicly_accessible = true
 skip_final_snapshot = true
 parameter_group_name = “default.mysql5.7”
tags = {
 Name = “Wp-database”
 }
}provider "google" {
 project = "qwiklabs-gcp-02-4aba9d16c1f2"
 region = "asia-southeast1"
 
}resource "google_compute_network" "vpc_network" {
 name = "wp-vpc"
 auto_create_subnetworks = false
 routing_mode = "REGIONAL"
}resource "google_compute_subnetwork" "subnet" {
 network = google_compute_network.vpc_network.id
 name = "wp-lab"
 ip_cidr_range = "10.0.11.0/24"
 region = "asia-southeast1"
 depends_on = [google_compute_network.vpc_network]
}resource "google_compute_firewall" "firewall" {
 name = "wp-firewall"
 network = google_compute_network.vpc_network.name
 source_ranges = [ "0.0.0.0/0" ]
 allow {
 protocol = "all"
 }
 depends_on = [google_compute_subnetwork.subnet]
}resource "google_container_cluster" "gce" {
 name = "wp-cluster"
 location = "asia-southeast1"
 remove_default_node_pool = true
 initial_node_count = 1
 network = google_compute_network.vpc_network.name
 subnetwork = google_compute_subnetwork.subnet.name
 depends_on = [google_compute_firewall.firewall]}resource "google_container_node_pool" "node_pool" {
 location = "asia-southeast1"
 name = "wp-node"
 cluster = google_container_cluster.gce.name
 node_count = 1
node_config {
 machine_type = "n1-standard-1"
 }
 depends_on = [google_container_cluster.gce]
}resource "null_resource" "one" {
 provisioner "local-exec" {
 command ="gcloud container clusters get-credentials wp-cluster - region=asia-southeast1"
 }
 
 depends_on=[google_container_node_pool.node_pool,]
}provider "kubernetes" {}
resource "kubernetes_deployment" "example" {
 metadata {
 name = "wordpressdeployment"
 labels = {
 test = "hello"
    }
  }
spec {
 replicas = 3
selector {
 match_labels = {
 test = "hello"
   }
  }
template {
 metadata {
 labels = {
 test = "hello"
 }
 }
spec {
 container {
 image = "wordpress:4.8-apache"
 name = "wordpresscontainer"
}
 }
 }
 }
 depends_on=[null_resource.one]
}resource "kubernetes_service" "wp-expose" {
 metadata {
 name = "terraform-wp-service"
 }
 spec {
 selector = {
 test = "hello"
 }
 
 port {
 
 port = 8080
 target_port = 80
 }
type = "LoadBalancer"
 }
 depends_on = [kubernetes_deployment.example]
}
output "WordPress-Address" {
 value = "${kubernetes_service.wp-expose.load_balancer_ingress.0.ip}"
}
