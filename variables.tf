# cat variables.tf

variable "region" {
    default = "ap-south-1"
}

variable "instance_type" {
    
    default = "t2.micro"
}

variable "project_name" {
    default = "zomato"
}

variable "project_env" {
    default = "dev"
}

variable "project_vpc_cidr" {
    default = "172.17.0.0/16"
}


