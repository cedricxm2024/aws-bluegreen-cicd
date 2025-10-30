output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app_lt.id
}
