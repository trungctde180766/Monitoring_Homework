#!/bin/bash
# Log execution start
echo "========================================="
echo "Starting CloudWatch Agent Installation & CPU Stress..."
echo "========================================="

# 1. Install CloudWatch Agent
echo "Installing CloudWatch Agent..."
sudo yum install amazon-cloudwatch-agent -y

# 2. Write CloudWatch Agent Configuration File
echo "Writing CloudWatch Agent Config..."
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "disk_used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  }
}
EOF

# 3. Start CloudWatch Agent using the configuration file
echo "Starting CloudWatch Agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 4. CPU Stress Test configuration
DURATION=600
END_TIME=$((SECONDS + DURATION))

stress_cpu() {
  while [ $SECONDS -lt $END_TIME ]; do
    # Run simple mathematical operations in a tight loop to consume 100% CPU
    _=$((1 + 1))
  done
}

# Run multiple loops in parallel to stress all vCPUs
# (t2.micro/t3.micro typically have 1 or 2 vCPUs)
stress_cpu &
stress_cpu &

echo "CloudWatch Agent is running, and CPU stress test started in the background (10 minutes)."
echo "You can check the CPU usage using the 'top' command on the instance."
