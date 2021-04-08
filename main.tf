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
    Name = "My_VPC"
}

} 


# Internet Gateway

resource "aws_internet_gateway" "ig-way" {
    vpc_id = "${aws_vpc.My_VPC.id}"

    tags= {
        Name = "ig_way"
    }
}


# Create 3 subnets

resource "aws_subnet" "subnet_1" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_1
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet1_zone

    tags ={
        Name = "subnet_1"
    }
}

resource "aws_subnet" "subnet_2" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_2
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet2_zone

    tags= {
        Name = "subnet_2"
    }
}

resource "aws_subnet" "subnet_3" {
    vpc_id = "${aws_vpc.My_VPC.id}"
    cidr_block = var.cidr_block_subnet_3
    map_public_ip_on_launch = "true"
    availability_zone = var.subnet3_zone

    tags= {
        Name = "subnet_3"
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
        Name = "route-table"
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
  description = "Allow TLS inbound traffic allow ports 8080"
  vpc_id = "${aws_vpc.My_VPC.id}"

  ingress {
    description = "Allow Load Balancer Access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_loadbalancer.id]
  }

    ingress {
    description = "Allow Load Balancer Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application"
  }
}

# resource "aws_instance" "ec2_instance" {
#   ami               = var.ami
#   instance_type     = "t2.micro"
#   availability_zone = "us-east-1a"
#   disable_api_termination = false
#   instance_initiated_shutdown_behavior = var.terminate
#   subnet_id = "${aws_subnet.subnet_1.id}"
#   security_groups   = ["${aws_security_group.application.id}"]
#   iam_instance_profile = "${aws_iam_instance_profile.ec2_s3_profile.name}"
#   key_name =  var.key_name
#     root_block_device {
#     volume_type = "gp2"
#     volume_size = 20
#     delete_on_termination = true
#   }
#   tags = {
#         Name = "ec2_instance- ${terraform.workspace}"
#   }

#   user_data = <<-EOF
# #! /bin/bash
# sudo echo export "S3_BUCKET_NAME=${aws_s3_bucket.bucket.bucket}" >> /etc/environment
# sudo echo export "DB_ENDPOINT=${element(split(":", aws_db_instance.RDS-Instance.endpoint), 0)}" >> /etc/environment
# sudo echo export "DB_NAME=${aws_db_instance.RDS-Instance.name}" >> /etc/environment
# sudo echo export "DB_USERNAME=${aws_db_instance.RDS-Instance.username}" >> /etc/environment
# sudo echo export "DB_PASSWORD=${aws_db_instance.RDS-Instance.password}" >> /etc/environment
# sudo echo export "AWS_REGION=${var.region}" >> /etc/environment
# sudo echo export "AWS_PROFILE=${var.profile}" >> /etc/environment
# EOF

# }


resource "aws_launch_configuration" "asg-config" {
  name = "asg_launch_config"
  image_id=var.ami
  instance_type="t2.micro"
  key_name="csye_spring_2021"
  associate_public_ip_address = true
  ebs_block_device {
        device_name = "/dev/sdg"
        volume_size = 20
        volume_type = "gp2"
        delete_on_termination = true
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
 sudo echo export "AWS_PROFILE=${var.profile}" >> /etc/environment
 sudo echo export "SNS_TOPIC=${aws_sns_topic.sns_topic.arn}" >> /etc/environment
 
 EOF

  iam_instance_profile = "${aws_iam_instance_profile.ec2_s3_profile.name}"
  security_groups= ["${aws_security_group.application.id}"]
 
}

// AutoScaling Group
resource "aws_autoscaling_group" "web_server_group" {
  name                      = "WebServerGroup"
  max_size                  = 5
  min_size                  = 3
  default_cooldown          = 60
  desired_capacity          = 3
  launch_configuration      = "${aws_launch_configuration.asg-config.name}"
  vpc_zone_identifier       = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}", "${aws_subnet.subnet_3.id}"]
  health_check_grace_period = 1200
  target_group_arns = ["${aws_lb_target_group.lb_tg_webapp.arn}"]
  tags =[
    {
      key                 = "Name"
      value               = "webapp"
      propagate_at_launch = true
    }
  ]
}

// ASG Scaleup policy
resource "aws_autoscaling_policy" "web_server_scaleup_policy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.web_server_group.name}"
}

// ASG Scaledown policy
resource "aws_autoscaling_policy" "web_server_scaledown_policy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.web_server_group.name}"
}
// ASG CW Alarm for scaleup
resource "aws_cloudwatch_metric_alarm" "cw_alarm_high" {
  alarm_name                = "CPUAlarmHigh"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "50"
  dimensions = "${map("AutoScalingGroupName", "${aws_autoscaling_group.web_server_group.name}")}"
  alarm_description         = "Scale-up if CPU > 50% for 5 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.web_server_scaleup_policy.arn}"]
}


// ASG CW Alarm for scaledown
resource "aws_cloudwatch_metric_alarm" "cw_alarm_low" {
  alarm_name                = "CPUAlarmLow"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "3"
  alarm_description         = "Scale-down if CPU < 3% for 5 minutes"
  dimensions = "${map("AutoScalingGroupName", "${aws_autoscaling_group.web_server_group.name}")}"
  alarm_actions     = ["${aws_autoscaling_policy.web_server_scaledown_policy.arn}"]
}


// Application Load Balancer
resource "aws_lb" "app_lb" {
  name = "appLoadBalancer"
  internal = false
  subnets = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}", "${aws_subnet.subnet_3.id}"]
  security_groups = ["${aws_security_group.sg_loadbalancer.id}"]
  load_balancer_type = "application"
  ip_address_type = "ipv4"
  enable_deletion_protection = false
  tags = {
      Name = "ec2_instance"
    }
}
resource "aws_lb_target_group" "lb_tg_webapp" {
  name     = "WebAppTargetGroup"
  target_type = "instance"
  health_check {
    port = "8080"
    interval = 10
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    path = "/"
  }  
  deregistration_delay = 20
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.My_VPC.id}"
}

resource "aws_lb_listener" "alb_listener1" {
  load_balancer_arn = "${aws_lb.app_lb.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_tg_webapp.arn}"
  }
}


resource "aws_security_group" "sg_loadbalancer" {
    name="LoadBalancer-Security-Group"
    description="Enable HTTPS via port 8080"
    vpc_id="${aws_vpc.My_VPC.id}"
    

  ingress {
    description = "Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  ingress {
    description = "Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  egress {
    description = "Port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }
    tags = {
        Name = "sg_loadbalancer"
    }
}



resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group
  
  subnet_ids = [aws_subnet.subnet_1.id,aws_subnet.subnet_2.id,aws_subnet.subnet_3.id]
  
  tags= {
    Name = "subnet-group-db"
  }

}

# Database security group.

resource "aws_security_group" "database" {
  name = "database security group"
  description = "Open port 3306 for Database traffic"
  vpc_id      = aws_vpc.My_VPC.id

  ingress {
    description = "Allow MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.application.id]
}
  tags= {
    Name = "database"
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
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  

  tags={
    Name="RDS-database"
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



# This policy is required for lambda  to download latest application revision.
resource "aws_iam_policy" "CodeDeploy_Lambda_S3" {
  name        = "CodeDeploy_Lamda_S3"
  description = "Policy for lamda instance to store and retrieve  artifacts in S3"
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
      "Resource": [ "${var.codedeploy_lambda_bucket_arn}" , "${var.codedeploy_lambda_bucket_arn_star}" ]
    }
  ]
}
EOF
}


resource "aws_iam_user_policy_attachment" "attach_ghactions_Lamda_S3" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Upload_To_S3.arn
}

resource "aws_iam_role_policy_attachment" "attach_Lamda_S3" {
  policy_arn = aws_iam_policy.CodeDeploy_Lambda_S3.arn
    role = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "attach_Codedeploy_Lamda_S3" {

  policy_arn = aws_iam_policy.CodeDeploy_Lambda_S3.arn
    role      = aws_iam_role.CodeDeployServiceRole.name
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



# policy allows GitHub Actions to call CodeDeploy APIs to initiate application deployment on EC2 instances.
resource "aws_iam_policy" "GH_Code_Deploy_Lambda" {
  name        = "Lamda_Codedeploy"
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
        "arn:aws:codedeploy:${var.aws_region}:${var.account_id}:application:${var.codedeploy_lambda}"
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

resource "aws_iam_user_policy_attachment" "attach_GH_Code_Deploy_Lamda" {
  user       = var.ghactions_username
  policy_arn = aws_iam_policy.GH_Code_Deploy_Lambda.arn
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


resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_policy_attacher_lambda" {
  role       = aws_iam_role.CodeDeployServiceRole.name
  policy_arn = var.CodeDeployServiceRole_lambda_policy

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

# Code Deploy Applicaiton 
resource "aws_codedeploy_app" "codedeploy_lambda_appname" {
  compute_platform = "Lambda"
  name             = var.codedeploy_lambda
}


#  CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
app_name = aws_codedeploy_app.codedeploy_app.name
deployment_group_name = "csye6225-webapp-deployment"
service_role_arn = aws_iam_role.CodeDeployServiceRole.arn
deployment_config_name = "CodeDeployDefault.OneAtATime"
autoscaling_groups = [aws_autoscaling_group.web_server_group.name]
load_balancer_info {
target_group_info {
name = aws_lb_target_group.lb_tg_webapp.name
}
}
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
#  ec2_tag_set {
# ec2_tag_filter {
# key = "Name"
# type = "KEY_AND_VALUE"
# value = "ec2_instance"
# }
# }

}


#  CodeDeploy Deployment Group for Lambda
resource "aws_codedeploy_deployment_group" "csye6225-lambda-deployment" {
app_name = aws_codedeploy_app.codedeploy_lambda_appname.name
deployment_group_name = "csye6225-lambda-deployment"
service_role_arn = aws_iam_role.CodeDeployServiceRole.arn
deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

}


resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attach" {
   role       = aws_iam_role.ec2role.name
   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  
}


# resource "aws_route53_record" "record" {
#   zone_id = var.zoneId
#   name    = var.record_name
#   type    = "A"
#   ttl     = "60"
#   records = [aws_instance.ec2_instance.public_ip]
# }

data "aws_route53_zone" "primary" {
  name         = var.record_name
}

// DNS Record
resource "aws_route53_record" "dns_record" {
  zone_id = var.zoneId
  name    = var.record_name
  type    = "A"
  alias {
    name                   = "${aws_lb.app_lb.dns_name}"
    zone_id                = "${aws_lb.app_lb.zone_id}"
    evaluate_target_health = true  
    }
}
output "appLoadBalancer" {
  value = "${aws_lb.app_lb.arn}"
}


resource "aws_dynamodb_table" "dynamodb" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "dynamodb"
  }
}

resource "aws_sns_topic" "sns_topic" {
  name = "sns_topic"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_iam_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda.name
}


resource "aws_lambda_function" "lambda" {
  filename      = "csye6225-lambda.zip"
  function_name = "csye6225"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 180
  publish = true


  runtime = "nodejs10.x"

  environment {
    variables = {
      Name = "Lambda Function"
    }
  }
}
resource "aws_lambda_alias" "lambda_alias" {
  name             = "lambdaalias"
  function_version = aws_lambda_function.lambda.version
  description      = "a sample description"
  function_name    = "csye6225"
  lifecycle {
    ignore_changes = [function_version]
}

  # routing_config {
  #   additional_version_weights = {
  #     "2" = 0.5
  #   }
  # }
}


resource "aws_iam_role_policy_attachment" "SNSPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  role       = aws_iam_role.ec2role.name
}


# resource "aws_s3_bucket" "lamda-bucket" {
#   bucket = var.lamda_bucket
#   acl = "private"
#   force_destroy = true
#   lifecycle_rule {
#     enabled = true
#     transition {
#       days = 30
#       storage_class = "STANDARD_IA"
#     }
#   }
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = var.encryption_algorithm
#       }
#     }
#   }
# }


resource "aws_s3_bucket_public_access_block" "webappBucketRemovePublicAccess" {
bucket = aws_s3_bucket.bucket.id
block_public_acls = true
block_public_policy = true
restrict_public_buckets = true
ignore_public_acls = true
}

# resource "aws_s3_bucket_public_access_block" "serverlessBucketRemovePublicAccess" {
# bucket = aws_s3_bucket.lamda-bucket.id
# block_public_acls = true
# block_public_policy = true
# restrict_public_buckets = true
# ignore_public_acls = true
# }

data "aws_iam_user" "ghactions_user" {
  user_name = "ghactions"
}

//adding lambda full access to gh actions user
resource "aws_iam_user_policy_attachment" "ghactions_attach_gh_serverless_upload_to_s3_policy" {
  user       = data.aws_iam_user.ghactions_user.user_name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_sns_topic_subscription" "user_updates_sns_target" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lambda.arn}"
}

resource "aws_lambda_permission" "lambda_sns_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}

resource "aws_iam_policy" "lambdapolicy" {
  name        = "lambdapolicy"
  path        = "/"
  description = "lambdapolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  policy_arn = aws_iam_policy.lambdapolicy.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_ses_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.iam_for_lambda.name
}
