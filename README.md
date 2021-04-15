# infrastructure
This repository contains terraform code for setting up infrastructure configurations.

## Commands to help while demo

To ssh into the EC2 instance
ssh -i .ssh/csye6225_spring2021 ubuntu@ipaddress


To scp the file to ec2 instance
scp -i ~/.ssh/csye6225_spring2021.pub /home/aditya/Desktop/csye6225spring2021/webapp.zip ubuntu@ipaddress:


Commands to set up MYSQL server inside the EC2 instance

sudo mysql

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'insert_password';

Create schema webapp;


Terraform command to change workspace

terraform workspace new "alpha"

Command to allow zsh to run shell scripts

chmod +x buildAMI.sh


The command to import certificate is as following:-

$ aws acm import-certificate --certificate fileb://certificate_body.pem --certificate-chain fileb://certificate_chain.pem --private-key fileb://private_key.pem

where,
--certificate is for certificate body,
-- certificate-chain is for certificate chain that is the ca-bundle file that Comodo gives
--private-key is the key the user created to generate the certificate.