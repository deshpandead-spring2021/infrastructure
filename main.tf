# Create VPC/Subnet/IG/Route Table

provider "aws" {
profile = var.profile
  region = "${var.region}"
}


# Create the VPC

resource "aws_vpc" "My_VPC" {
cidr_block           = var.vpcCIDRblock
instance_tenancy = "default"
enable_dns_support = var.dnsSupport
enable_classiclink_dns_support = true
enable_dns_hostnames = var.dnsHostNames
assign_generated_ipv6_cidr_block = false
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


# Route table association with subnets.

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
  description = "Allow TLS inbound traffic allow ports 22,80,443,8080"
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

resource "aws_instance" "ec2_instance" {
  ami               = var.ami
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = var.terminate
  subnet_id = "${aws_subnet.subnet_1.id}"
  security_groups   = ["${aws_security_group.application.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_s3_profile.name}"
  key_name =  var.key_name
    root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }
  tags = {
        Name = "ec2_instance- ${terraform.workspace}"
  }

  user_data = <<-EOF
#! /bin/bash
sudo echo export "S3_BUCKET_NAME=${aws_s3_bucket.bucket.bucket}" >> /etc/environment
sudo echo export "DB_ENDPOINT=${element(split(":", aws_db_instance.RDS-Instance.endpoint), 0)}" >> /etc/environment
sudo echo export "DB_NAME=${aws_db_instance.RDS-Instance.name}" >> /etc/environment
sudo echo export "DB_USERNAME=${aws_db_instance.RDS-Instance.username}" >> /etc/environment
sudo echo export "DB_PASSWORD=${aws_db_instance.RDS-Instance.password}" >> /etc/environment
sudo echo export "AWS_REGION=${var.region}" >> /etc/environment
sudo echo export "AWS_PROFILE=${var.profile}" >> /etc/environment
EOF

}


resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group
  
  subnet_ids = [aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  
  tags = {
    Name = "subnet-group-db -${terraform.workspace}"
  }

}

# Database security group.

resource "aws_security_group" "database" {
  name = "database security group"
  description = "Open port 3306 for Database traffic"
  vpc_id      = aws_vpc.My_VPC.id

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_subnet_1]
  }
    # Allow all outbound traffic.
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block_subnet_1]
  }
  
  tags = {
    Name = "database- ${terraform.workspace}"
  }
}


# RDS instance

resource "aws_db_instance" "RDS-Instance" { 
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.21"
  identifier           = var.db_identifier
  instance_class       = "db.t2.micro"
  name                 = "csye6225"
  username             = "csye6225"
  password             = var.password_db
  parameter_group_name = "default.mysql8.0"
  publicly_accessible     = "false"
  multi_az                = "false"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  

  tags ={
    Name="RDS database- ${terraform.workspace}"
  }
}

## Creation of S3 bucket.
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucketname
  acl = "private"
  force_destroy = true
  lifecycle_rule {
    enabled = true
    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.encryption_algorithm
      }
    }
  }
}

# IAM POLICY
resource "aws_iam_policy" "WebAppS3" {
  name        = var.s3policyName
  description = "Policy for EC2 instance to use S3"
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": ["${aws_s3_bucket.bucket.arn}","${var.bucketARN}" ]
    }
  ]
}
EOF
}

# IAM ROLE
resource "aws_iam_role" "ec2role" {
  name = var.s3roleName
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
    "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
  tags = {
    Name = "Custom Access Policy for EC2-S3"
  }
}


resource "aws_iam_role_policy_attachment" "role_policy_attacher" {
  role       = aws_iam_role.ec2role.name
  policy_arn = aws_iam_policy.WebAppS3.arn
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attacher" {
  role       = aws_iam_role.ec2role.name
  policy_arn = aws_iam_policy.CodeDeploy_EC2_S3.arn
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = var.ec2InstanceProfile
  role = aws_iam_role.ec2role.name
}


# This policy is required for EC2 instances to download latest application revision.
resource "aws_iam_policy" "CodeDeploy_EC2_S3" {
  name        = "${var.CodeDeploy-EC2-S3}"
  description = "Policy for EC2 instance to store and retrieve  artifacts in S3"
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [ "${var.codedeploy_bucket_arn}" , "${var.codedeploy_bucket_arn_star}" ]
    }
  ]
}
EOF
}

# Policy allows GitHub Actions to upload artifacts from latest successful build to dedicated S3 bucket used by CodeDeploy.
resource "aws_iam_policy" "GH_Upload_To_S3" {
  name        = "${var.GH-Upload-To-S3}"
  description = "Policy for Github actions script to store artifacts in S3"
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [ "${var.codedeploy_bucket_arn}" , "${var.codedeploy_bucket_arn_star}" ]
    }
  ]
}
EOF
}


# policy allows GitHub Actions to call CodeDeploy APIs to initiate application deployment on EC2 instances.
resource "aws_iam_policy" "GH_Code_Deploy" {
  name        = "${var.GH-Code-Deploy}"
  description = "Policy allows GitHub Actions to call CodeDeploy APIs to initiate application deployment on EC2 instances."
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:application:${var.codedeploy_appname}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}


# create Role for Code Deploy
resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = var.CodeDeployEC2ServiceRole
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
    "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
  tags = {
    Name = "CodeDeployEC2ServiceRole access policy"
  }
}


#attaching CodeDeploy_EC2_S3 policy to ghactions  user
resource "aws_iam_user_policy_attachment" "attach_GH_Upload_To_S3" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Upload_To_S3.arn
}

#attaching GH_Code_Deploy policy to ghactions  user
resource "aws_iam_user_policy_attachment" "attach_GH_Code_Deploy" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Code_Deploy.arn
}


#create CodeDeployServiceRole role
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = var.CodeDeployServiceRole
  # policy below has to be edited
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Name = "CodeDeployEC2Role access policy"
  }
}


resource "aws_iam_role_policy_attachment" "CodeDeployEC2ServiceRole_webapps3_policy_attacher" {
  role       = aws_iam_role.CodeDeployEC2ServiceRole.name
  policy_arn = aws_iam_policy.WebAppS3.arn
}


resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_policy_attacher" {
  role       = aws_iam_role.CodeDeployServiceRole.name
  policy_arn = var.CodeDeployServiceRole_policy
}




#attach policies to codedeploy role
resource "aws_iam_role_policy_attachment" "CodeDeployEC2ServiceRole_policy_attacher" {
  role       = aws_iam_role.CodeDeployEC2ServiceRole.name
  policy_arn = aws_iam_policy.CodeDeploy_EC2_S3.arn
}

# Code Deploy Applicaiton 
resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "Server"
  name             = var.codedeploy_appname
}


#  CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "example" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = var.codedeploy_group
  service_role_arn      = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "ec2_instance- ${terraform.workspace}"
    }
  }
}


resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attach" {
   role       = aws_iam_role.ec2role.name
   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  
}


resource "aws_route53_record" "record" {
  zone_id = var.zoneId
  name    = var.record_name
  type    = "A"
  ttl     = "60"
  records = [aws_instance.ec2_instance.public_ip]
}
data "aws_route53_zone" "primary" {
  name         = var.record_name
}
