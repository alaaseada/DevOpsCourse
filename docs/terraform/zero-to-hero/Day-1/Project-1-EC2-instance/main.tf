# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a variable to hold EC2 instances we need to create (list of objects)
variable "ec2" {
  type = map(object({
    ami = string
    instance_type = string
    tags = map(string)
    sgs = map(object({
     port = number
    }))
  }))
  default = {
    "RHEL-1" = {
      ami = "ami-0fe630eb857a6ec83"
      instance_type = "t2.micro"
      tags = {
       name = "RHEL-1"
       OS = "rhel"
      }
      sgs = {
       administration = {
        port = 22
       },
       web = {
        port = 80
       }
      }
    },
    "Ubuntu-1" = {
      ami = "ami-04b70fa74e45c3917"
      instance_type = "t2.micro"
      tags = {
       name = "Ubuntu-1"
       OS = "ubuntu"
      }
      sgs = {
       administration = {
        port = 22
       },
       webSecure = {
        port = 443
       }
      }
    }
  }
}

# Dynamically create security groups the ec2 instances with the same tags as EC2 instances
resource "aws_security_group" "instace_sg" {
  for_each = var.ec2
  name = "${each.key}-sg"
  description = "Security group for ${each.key}"

  dynamic "ingress" {
   for_each = each.value.sgs

   content {
     from_port = ingress.value.port
     to_port = ingress.value.port
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
     description = "Allow inbound traffic on port ${ingress.value.port}"
   }
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = each.value.tags
}

# Create a key pair 
# I imported the one I've already has 
# Create an empty aws_key_pair resource, run terraform import aws_key_pair <name of key on AWS console>, terraform show, copy resource and paste it 
# in .tf, remove everything but the key name, add public_key with value file("~/.ssh/public key"), terraform plan, apply
resource "aws_key_pair" "deployer" {
    key_name        = "ubuntu-machine-1-key"
    public_key      = file("~/.ssh/ubuntu-machine-1-pub-key.pub")
}

# Create the EC2 instances and dynamically assign the SGs based on tags
resource "aws_instance" "this" {
  for_each = var.ec2
  ami = each.value["ami"]
  instance_type = each.value["instance_type"]
  tags = each.value["tags"]
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [
   each.value.tags.OS == "rhel" ? aws_security_group.instace_sg["RHEL-1"].id : aws_security_group.instace_sg["Ubuntu-1"].id
  ]
}


# https://www.youtube.com/watch?v=_z36lM4CkgU
# https://medium.com/@riyasrawther.in/terraform-tutorial-dynamic-aws-ec2-instances-with-security-groups-e43f9a1e82ab