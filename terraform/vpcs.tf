module "vpc" "first"{
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = "terraform-vpc-first"

  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "vpc" "second"{
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = "terraform-vpc-second"

  cidr = "10.1.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.1.0.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_vpc_peering_connection" "pc" {
  peer_vpc_id = "${module.vpc.first.vpc_id}"
  vpc_id      = "${module.vpc.second.vpc_id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "VPC peering"
  }
}

resource "aws_route" "vpc-peering-route-second" {
  count                     = 2
  route_table_id            = "${module.vpc.second.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc.first.public_subnets_cidr_blocks[count.index]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}

resource "aws_route" "vpc-peering-route-first" {
  count                     = 2
  route_table_id            = "${module.vpc.first.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc.second.public_subnets_cidr_blocks[count.index]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${module.vpc.first.vpc_id}"
  service_name = "com.amazonaws.s3-website-us-east-1.s3-static-test-page"
}