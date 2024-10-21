provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  # If not set, cn-beijing will be used.
  region = "me-central-1"
}

resource "alicloud_ecs_key_pair" "tf_key_nginx" {
  key_pair_name = "tf_key_nginx"
  key_file = "tf_key_nginx.pem"
} 

resource "alicloud_vpc" "vpc" {
  vpc_name   = "vpc"
  cidr_block = "10.0.0.0/8"
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}
resource "alicloud_vswitch" "switch1" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = "10.0.1.0/24"
  zone_id      = data.alicloud_zones.default.zones.0.id
  vswitch_name = "switch1"
}


resource "alicloud_instance" "nginx" {
  # cn-beijing
  availability_zone = data.alicloud_zones.default.zones.0.id
  security_groups   = [alicloud_security_group.nginx.id]

  # series III
  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_size           = "40"
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  instance_name              = "nginx"
  vswitch_id                 = alicloud_vswitch.switch1.id
  internet_max_bandwidth_out = 100
  internet_charge_type = "PayByTraffic"
  instance_charge_type = "PostPaid"
  user_data = base64encode(file("startup.sh"))
  key_name = "tf_key_nginx"

}

output "nginx-ip" {
  value = alicloud_instance.nginx.*.public_ip
}


resource "alicloud_security_group" "nginx" {
  name   = "nginx-sg"
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_ssh_from_outside" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.nginx.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http_from_outside" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.nginx.id
  cidr_ip           = "0.0.0.0/0"
}

