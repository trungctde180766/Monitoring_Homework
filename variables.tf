variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-southeast-1"
}

variable "alert_email" {
  type        = string
  description = "The email address to subscribe to the SNS topic for CPU alarms"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type"
  default     = "t2.micro"
}

variable "enable_recovery_notification" {
  type        = bool
  description = "Enable notification when the system recovers back to OK state"
  default     = true
}
