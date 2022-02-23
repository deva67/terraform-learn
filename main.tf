provider "aws" {
    region = "us-east-2"
}

variable "cider_block" {
  description = "list cider block"
  type = list(object(
      {
          cider_block = string
          name = string
      }
  ))
  }


variable "vpc_cider_block" {
  description = "vpc cider block"
}


variable "environment" {
  description = "environment deployment"
}


resource "aws_vpc" "development-vpc" {
    cidr_block = var.cider_block[0].cider_block
    tags = {
        Name: var.cider_block[0].name
        vpc_env = "dev"
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.cider_block[1].cider_block
    availability_zone = "us-east-2a"
    tags = {
        Name: var.cider_block[1].name
    }

  }

data "aws_vpc" "existing_vpc" {
  default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "172.31.48.0/20"
    availability_zone = "us-east-2a"
    tags = {
        Name: "subnet-2-default"
    }

  }

output "dev_vpd_id" {
    value = aws_vpc.development-vpc.id
}