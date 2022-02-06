provider "aws" {
   region     = "us-east-1"
}

resource "aws_vpc" "sandbox-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags =  {
        Name = "sandbox-vpc"
    }
}

resource "aws_subnet" "sandbox-subnet-public-1" {
    vpc_id = "${aws_vpc.sandbox-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags =  {
        Name = "sandbox-subnet-public-1"
    }
}

resource "aws_internet_gateway" "sandbox-igw" {
    vpc_id = "${aws_vpc.sandbox-vpc.id}"
    tags =  {
        Name = "sandbox-igw"
    }
}

resource "aws_route_table" "sandbox-public-crt" {
    vpc_id = "${aws_vpc.sandbox-vpc.id}"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.sandbox-igw.id}" 
    }
    
    tags =  {
        Name = "sandbox-public-crt"
    }
}

resource "aws_route_table_association" "sandbox-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.sandbox-subnet-public-1.id}"
    route_table_id = "${aws_route_table.sandbox-public-crt.id}"
}

resource "aws_security_group" "ec2-web_sg" {
  name   = "ec2_web_sg"
  vpc_id = "${aws_vpc.sandbox-vpc.id}"
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
    tags =  {
        Name = "ssh-allowed"
    }
}

resource "aws_instance" "sandbox_web" {
    ami = "ami-0c2a1acae6667e438"
    instance_type = "t2.micro"
    # VPC
    subnet_id = "${aws_subnet.sandbox-subnet-public-1.id}"
    # Security Group
    vpc_security_group_ids = ["${aws_security_group.ec2-web_sg.id}"]
    private_ip = "10.0.1.15"
}

resource "aws_volume_attachment" "sandbox_web_1" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.sandbox_web_1.id}"
  instance_id = "${aws_instance.sandbox_web.id}"
}

resource "aws_volume_attachment" "sandbox_web_2" {
  device_name = "/dev/sdk"
    volume_id   = "${aws_ebs_volume.sandbox_web_2.id}"
  instance_id = "${aws_instance.sandbox_web.id}"
}

resource "aws_ebs_volume" "sandbox_web_1" {
  availability_zone = "us-east-1a"
  size              = 50
}


