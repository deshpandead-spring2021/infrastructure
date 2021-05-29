# Terraform - Infrastrcutre as a Code
This repository contains terraform code for setting up infrastructure configurations. Terraform is a code tool from HahiCorp. It is a tool for building, changing and managing infrastructure in a safe, repeatable way. Developers and Infrastructure teams can use Terraform to mange environments with a configuration language called the HashiCorp Configuration Language (HCL) for human readable, automated deployments.

# Prerequisites:

1. Cloud Provider - Amazon Web Services
2. CLI access setup for above account
3. Terraform installed on local machine
   
# Steps:

The basic workflow steps of Terraform deployment is as follows:

1. **Scope** - Confirm what resources need to be created for a given project.
2. **Author**- Create the configuration file in HCL based on the scoped parameters.
3. **Initialize** - Run *`terraform init`*  in the project directory with the configuarion files. This will download the correct provider plug-ins for the project.
4. **Plan & Apply** - Run `*terraform plan*` to verify creation process and then terraform apply to create real resources as well as state file that compares future changes in your configuration files to what actually exists in your deployment environment. Upon `*terraform apply*`, the user will be prompted to review the proposed changes and must affirm the changes or else Terraform will not apply the proposed plan.
5. **Destroy** - The *`terraform destroy`* command terminates resources defined in your Terraform configuration. This command is the reverse of *`terraform apply`* in that it terminates all the resources specified by the configuration. It does not destroy resources running elsewhere that are not described in the current configuration.Just like with apply, Terraform determines the order in which things must be destroyed.

# Important commands that are helpful for setting up Infrastructure

1. To ssh into the EC2 instance
*ssh -i .ssh/key-pair ubuntu@ipaddress*

2. To scp the file to ec2 instance
*scp -i ~/.ssh/key-pair /home/aditya/Desktop/csye6225spring2021/webapp.zip ubuntu@ipaddress:*


3. Commands to set up MYSQL server inside the EC2 instance
    *sudo mysql*
    *ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'insert_password'*;
    *Create schema webapp*;

4. Terraform command to change workspace
   *terraform workspace new "alpha"*

5. Command to allow zsh to run shell scripts (This command is useful if *bash* is your default terminal
   *chmod +x buildAMI.sh*

6. The command to import certificate is as following:-
   *aws acm import-certificate --certificate fileb://certificate_body.pem --certificate-chain fileb:// certificate_chain.pem --private-key fileb://private_key.pem* 
    where,
    --certificate is for certificate body,
    -- certificate-chain is for certificate chain that is the ca-bundle file that Comodo gives
    --private-key is the key the user created to generate the certificate.