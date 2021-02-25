# Create VPC/Subnet/IG/Route Table

provider "aws" {
region  = var.region
profile = var.profile
}


# Create the VPC

resource "aws_vpc" "My_VPC" {
cidr_block           = var.vpcCIDRblock
instance_tenancy = "default"
enable_dns_support = var.dnsSupport
enable_dns_hostnames = var.dnsHostNames
  tags= {
    Name = "My_VPC - ${terraform.workspace}"
}

} 


# Internet Gateway

resource "aws_internet_gateway" "ig-way" {
    vpc_id = "${aws_vpc.My_VPC.id}"

    tags= {
        Name = "ig_way - ${terraform.workspace}"
    }
}


# Create 3 subnets


resource "aws_subnet" "subnet_1" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_1
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet1_zone

    tags ={
        Name = "subnet_1- ${terraform.workspace}"
    }
}

resource "aws_subnet" "subnet_2" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_2
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet2_zone

    tags= {
        Name = "subnet_2- ${terraform.workspace}"
    }
}

resource "aws_subnet" "subnet_3" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_3
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet3_zone

    tags= {
        Name = "subnet_3- ${terraform.workspace}"
    }
}

# route tables
resource "aws_route_table" "route-table" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.ig-way.id}"
    }

    tags= {
        Name = "route-table- ${terraform.workspace}"
    }
}


resource "aws_route_table_association" "subnet_1-a" {
    subnet_id = "${aws_subnet.subnet_1.id}"
    route_table_id = "${aws_route_table.route-table.id}"
}

resource "aws_route_table_association" "subnet_2-a" {
    subnet_id = "${aws_subnet.subnet_2.id}"
    route_table_id = "${aws_route_table.route-table.id}"
}

resource "aws_route_table_association" "subnet_3-a" {
    subnet_id = "${aws_subnet.subnet_3.id}"
    route_table_id = "${aws_route_table.route-table.id}"
}


## Security Groups

resource "aws_security_group" "application" {
  name        = "application"
  description = "Allow TLS inbound traffic"
  vpc_id = "${aws_vpc.My_VPC.id}"


  ingress {
  
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
    ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
    # Allow all outbound traffic.
   egress {
    from_port   = 0
    to_port     = 0 
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "application- ${terraform.workspace}"
  }
}