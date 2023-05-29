provider "aws" {
    # using paris region
    region = "eu-west-3"
}




# Create cluster of 4 nodes that are placed 
# In the same availability zone using placement group

# Locals variables 
# gathered configuration that are rarely changed
locals {
    ami_id = "ami-05b0538330217dad4"
    instance_type = "c6gd.medium" # One of the cheapest instance type that support cluster placement group 
    availability_zone = "eu-west-3a"
}

# Create placement group
resource "aws_placement_group" "cluster" {
    name = "cluster"
    strategy = "cluster"
}

# Create key pair
resource "aws_key_pair" "cluster" {
    key_name = "cluster_key"
    public_key = file(var.public_key_path)
}

# Create security group
resource "aws_security_group" "cluster" {
    name = "cluster"
    description = "Allow SSH and HTTP inbound traffic"
    vpc_id = data.aws_vpc.cluster.id

    ingress {
        description = "SSH from VPC"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "All outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "cluster"
    }
}


resource "aws_instance" "cluster" {
    count = var.vm_count
    ami = local.ami_id
    instance_type = local.instance_type
    availability_zone = local.availability_zone
    placement_group = aws_placement_group.cluster.name
    key_name = aws_key_pair.cluster.key_name
    vpc_security_group_ids = [aws_security_group.cluster.id]
    
    # Update the inventory file for ansible
    # This is a local-exec provisioner
    # It will run after the creation of the cluster
    # It will update the inventory file with the public IP of the cluster nodes
    provisioner "local-exec" {
        working_dir = "../machine_setup"
        command = <<EOF
            if [ $INDEX -eq 0 ]; then
                echo "Master ansible_host=$IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_PATH ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory.ini
            else
                echo "Node_$INDEX ansible_host=$IP ansible_user=ubuntu ansible_ssh_private_key_file=$KEY_PATH ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory.ini
            fi
        EOF
        environment = {
            INDEX = count.index
            IP = self.public_ip
            KEY_PATH = var.private_key_path
        }
    }
    provisioner "local-exec" {
        when = destroy
        working_dir = "../machine_setup"
        command = <<EOF
            cat .inv_def.ini > inventory.ini
        EOF
    }
    tags = {
        Name = "${count.index != 0 ? "Node-${count.index}" : "Master-Node"}"
    }
}