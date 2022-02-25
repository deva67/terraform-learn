provider "aws" {
    region="us-east-2"
}

variable vpc_cider_block {}
variable subnet_cider_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type{}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cider_block
    tags = {
        Name: "${var.env_prefix}-vpc"
         }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cider_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }

}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
} 

/*resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
     }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}*/


/*resource "aws_route_table_association" "a-rtb_assoiation" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}*/

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
     }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}
/*
resource "aws_security_group" "myapp-sg"{
  name = "myapp-sg" */

resource "aws_default_security_group" "default-sg"{
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
   }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
    }
   tags = {
        Name: "${var.env_prefix}-default-sg"
    } 
}

data "aws_ami" "latest-amazon-linux_image" {
    most_recent = true
    owners = [ "amazon" ]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-*-gp2"]    
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]    
    }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux_image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux_image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = "deva-Feb2022"
    
    user_data = <<EOF
                      #!/bin/bash
                      sudo yum update -y && sudo yum install -y docker
                      sudo systemctl start docker
                      sudo  usermod -aG docker ec2-user
                      docker run -p 8080:80 nginx
                EOF
    tags = {
        Name: "${var.env_prefix}-server"
    } 

}

