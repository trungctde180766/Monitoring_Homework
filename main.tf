# Get the default VPC in the region
data "aws_vpc" "default" {
  default = true
}

# Get subnets inside the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }
}

# Security group to allow SSH and basic HTTP access
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-monitoring-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-monitoring-sg"
  }
}

# Create the IAM Role for EC2 to allow CloudWatch Agent to push metrics
resource "aws_iam_role" "ec2_monitoring_role" {
  name = "ec2-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the CloudWatchAgentServerPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  role       = aws_iam_role.ec2_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create the IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-monitoring-instance-profile"
  role = aws_iam_role.ec2_monitoring_role.name
}

# Create the EC2 instance and run a CPU stress script via user_data
resource "aws_instance" "monitored_instance" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  user_data = file("${path.module}/scripts/stress_cpu.sh")

  tags = {
    Name = "Monitored-EC2-Instance"
  }
}

# Create the SNS Topic for Alerts (Standard)
resource "aws_sns_topic" "cpu_alarm_topic" {
  name         = "ec2-cpu-alarm-topic"
  display_name = "EC2 CPU Alarm Alert"
}

# Create the Email Subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Create the CloudWatch Metric Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "ec2-cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Send an email alert when EC2 CPU > 80% for 5 consecutive minutes"

  dimensions = {
    InstanceId = aws_instance.monitored_instance.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm_topic.arn]
  ok_actions    = var.enable_recovery_notification ? [aws_sns_topic.cpu_alarm_topic.arn] : []
}

# Create the CloudWatch Metric Alarm for Memory Utilization (Custom Agent Metric)
resource "aws_cloudwatch_metric_alarm" "memory_high_alarm" {
  alarm_name          = "ec2-memory-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Send an email alert when EC2 Memory usage > 80% for 5 consecutive minutes"

  dimensions = {
    InstanceId = aws_instance.monitored_instance.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm_topic.arn]
  ok_actions    = var.enable_recovery_notification ? [aws_sns_topic.cpu_alarm_topic.arn] : []
}
