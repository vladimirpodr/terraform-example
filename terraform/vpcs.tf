module "vpc-west" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.17.0"

  name = "terraform-vpc-west"

  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "vpc-east" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.17.0"

  name = "terraform-vpc-east"

  cidr = "10.1.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.1.0.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}



resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc-west.main_id
  service_name = "com.amazonaws.s3-website-us-east-1.s3-static-test-page"
}
