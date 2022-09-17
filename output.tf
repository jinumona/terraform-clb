# vim output.tf

output "latest-ami" {
    value = data.aws_ami.amazon.image_id
}

output "elb-endpoint" {
    
    value = "http://${aws_elb.myclb.dns_name}"
}

