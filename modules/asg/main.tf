data "template_file" "user_data" {
  template = file(var.user_data_file)
}

# Use Ubuntu Free Tier AMI (check region)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" # Free Tier eligible
  key_name      = var.key_name

  iam_instance_profile {
    name = var.instance_profile
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(file(var.user_data_file))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-app"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.name_prefix}-asg"
  desired_capacity           = 1
  max_size                   = 2
  min_size                   = 1
  health_check_type          = "EC2"
  vpc_zone_identifier        = var.subnet_ids
  target_group_arns          = [var.target_group_arn]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
