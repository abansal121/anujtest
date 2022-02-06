provider "aws" {
  access_key = "AKIASDZP5HXHBHG2UOEG"
  secret_key = "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"
  region     = "us-east-1"
}

resource "aws_vpc" "sandbox-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags {
        Name = "sandbox-vpc"
    }
}

resource "aws_subnet" "sandbox-subnet-public-1" {
    vpc_id = "sandbox-vpc"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-2a"
    tags {
        Name = "sandbox-subnet-public-1"
    }
}

resource "aws_internet_gateway" "sandbox-igw" {
    vpc_id = "sandbox-vpc"
    tags {
        Name = "sandbox-igw"
    }
}

resource "aws_route_table" "sandbox-public-crt" {
    vpc_id = "sandbox-vpc"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = "sandbox-igw" 
    }
    
    tags {
        Name = "sandbox-public-crt"
    }
}

resource "aws_route_table_association" "sandbox-crta-public-subnet-1"{
    subnet_id = "sandbox-subnet-public-1"
    route_table_id = "sandbox-public-crt"
}

resource "aws_security_group" "ec2-web_sg" {
  name   = "ec2_web_sg"
  vpc_id = "sandbox-vpc"
egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the NGIX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Name = "ssh-allowed"
    }
}

resource "aws_instance" "sandbox_web" {
    ami = "ami-0c2a1acae6667e438"
    instance_type = "t2.micro"
    # VPC
    subnet_id = "sandbox-subnet-public-1"
    # Security Group
    vpc_security_group_ids = ["ec2-web_sg"]
}
