
# vim main.tf

module "vpc" {
    
  source = "/home/ec2-user/t-10-lb/vpc-module/"
  vpc_cidr = var.project_vpc_cidr
  project  = var.project_name
  env      = var.project_env
}

output "vpc_module_return" {
    
  value = module.vpc
}
#---------------




# Creating Security Group 

resource "aws_security_group" "sg" {
 name_prefix        = "asg-${var.project_name}-${var.project_env}-"
  description = "Allow 22,80,443"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "allow 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
   cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
    
     ingress {
    description      = "allow 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    
     ingress {
    description      = "allow 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
   
    tags = {
    
    Name = "asg-${var.project_name}-${var.project_env}"
    project = var.project_name
    env = var.project_env
}
}


# creating key pair

resource "aws_key_pair" "key" {
  key_name   = "${var.project_name}-${var.project_env}"
  public_key = file("localkey.pub")
    
    tags = {
    
    Name = "${var.project_name}-${var.project_env}"
    project = var.project_name
    env = var.project_env
}
}

# clb

resource "aws_elb" "myclb" {
  name_prefix                 = "myclb-"
  subnets                     = [module.vpc.public1_subnet_id,module.vpc.public2_subnet_id]
  security_groups             = [aws_security_group.sg.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 30
  connection_draining         = true
  connection_draining_timeout = 5

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
    
     listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:ap-south-1:516234497646:certificate/f0e761e7-4bcf-4381-ba79-a98871b27354"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  

  tags = {
    Name = "myalb-${var.project_name}-${var.project_env}"
  }
}


# route53

resource "aws_route53_record" "www" {
  zone_id = "Z021753469ATO9CLJ96Z"
  name    = "inenso.in"
  type    = "A"

  alias {
    name                   = aws_elb.myclb.dns_name
    zone_id                = aws_elb.myclb.zone_id
    evaluate_target_health = true
  }
}



# aws_launch_configuration

resource "aws_launch_configuration" "myapp" {
  name_prefix   = "myapp-"
  image_id      =  data.aws_ami.amazon.image_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key.key_name 
  user_data     = file("setup.sh")
  security_groups = [aws_security_group.sg.id]
    
    lifecycle {
    create_before_destroy = true
  }
    
}

# auto scaling group

resource "aws_autoscaling_group" "myapp" {
  name_prefix         = "myasg-"
  desired_capacity    = "2"
  max_size            = "2"
  min_size            = "2"
wait_for_elb_capacity = "2"
   health_check_type  = "EC2"
 vpc_zone_identifier  = [module.vpc.public1_subnet_id,module.vpc.public2_subnet_id]
launch_configuration  = aws_launch_configuration.myapp.name
      load_balancers  = [aws_elb.myclb.id]


    
    
    lifecycle {
    create_before_destroy = true
  }
    
    
    tag {
    key = "Name"
    propagate_at_launch = true
    value = "myapp"
  }
    
}



