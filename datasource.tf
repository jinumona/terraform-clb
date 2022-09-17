# vim datasource.tf

data "aws_ami" "amazon" {
  
  owners        = ["amazon"]
  most_recent  = true
    

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
