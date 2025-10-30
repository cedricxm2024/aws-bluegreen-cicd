output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  value = aws_security_group.app_sg.id
}
output "sns_topic_arn" {
  value = aws_sns_topic.monitoring.arn
  description = "SNS topic ARN for monitoring and notifications"
}
