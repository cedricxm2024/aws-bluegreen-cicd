output "alb_arn" { value = aws_lb.alb.arn }
output "alb_dns_name" { value = aws_lb.alb.dns_name }
output "target_group_arn" { value = aws_lb_target_group.app_tg.arn }
output "target_group_name" { value = aws_lb_target_group.app_tg.name }
#############################################
# modules/alb/outputs.tf
#############################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_target_group_arn" {
  description = "ARN of the Target Group for the ALB"
  value       = aws_lb_target_group.this.arn
}
