#############################################
# envs/dev/outputs.tf
#############################################

output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_target_group" {
  description = "Target group ARN"
  value       = module.alb.alb_target_group_arn
}
