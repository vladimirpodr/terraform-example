variable "region" {
  default = "us-east-1"
}

variable "domain_name" {
  default = "terraform-example.s3-website-us-east-1.amazonaws.com"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.domain_name}"
  region = "${var.region}"
  acl = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadForGetBucketObjects",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": ["arn:aws:s3:::${var.domain_name}/*"]
  }]
}
EOF
}

resource "aws_s3_bucket_object" "index_file" {
  bucket = "${var.domain_name}"
  source = "../dist/index.html"
  key = "index.html"
  etag = "${md5(file("../dist/index.html"))}"
  content_type = "text/html"
  depends_on = [
    "aws_s3_bucket.site"
  ]
}

resource "aws_s3_bucket_object" "error_file" {
  bucket = "${var.domain_name}"
  source = "../dist/error.html"
  key = "error.html"
  etag = "${md5(file("../dist/error.html"))}"
  content_type = "text/html"
  depends_on = [
    "aws_s3_bucket.site"
  ]
}

resource "aws_s3_bucket_object" "css_file" {
  bucket = "${var.domain_name}"
  source = "../dist/assets/stylesheets/application.css"
  key = "assets/stylesheets/application.css"
  etag = "${md5(file("../dist/assets/stylesheets/application.css"))}"
  content_type = "text/css"
  depends_on = [
    "aws_s3_bucket.site"
  ]
}

resource "aws_s3_bucket_object" "image_file" {
  bucket = "${var.domain_name}"
  source = "../dist/assets/images/scape_long.png"
  key = "assets/images/scape_long.png"
  etag = "${md5(file("../dist/assets/images/scape_long.png"))}"
  content_type = "image/png"
  depends_on = [
    "aws_s3_bucket.site"
  ]
}

resource "aws_route53_zone" "primary" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "site" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "${var.domain_name}"
  type = "A"
  alias {
    name = "${aws_s3_bucket.site.website_domain}"
    zone_id = "${aws_s3_bucket.site.hosted_zone_id}"
    evaluate_target_health = false
  }
}




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


module "ec2_instances" "ec2_vpc_first"{
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "my-ec2-for-vpc-first"
  instance_count = 1

  ami                    = "ami-0c5204531f799e0c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = "${module.vpc.first.default_security_group_id}"
  subnet_id              = "${module.vpc.first.public_subnets[0]}"

  tags = {
    Terraform   = "true"
  }
}

module "ec2_instances" "ec2_vpc_second"{
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "my-ec2-for-vpc-second"
  instance_count = 1

  ami                    = "ami-0c5204531f799e0c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = "${module.vpc.second.default_security_group_id}"
  subnet_id              = "${module.vpc.second.privat_subnets[0]}"

  tags = {
    Terraform   = "true"
  }
}