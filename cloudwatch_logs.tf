resource "aws_cloudwatch_log_group" "messages" {
  name              = "/var/log/messages"
  retention_in_days = 1

  tags {
    Log = "/var/log/messages"
  }
}

resource "aws_cloudwatch_log_group" "dmesg" {
  name              = "/var/log/dmesg"
  retention_in_days = 1

  tags {
    Log = "/var/log/dmesg"
  }
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "/var/log/docker"
  retention_in_days = 1

  tags {
    Log = "/var/log/docker"
  }
}

resource "aws_cloudwatch_log_group" "ssm-agent" {
  name              = "/var/log/amazon/ssm/amazon-ssm-agent.log"
  retention_in_days = 1

  tags {
    Log = "/var/log/amazon/ssm/amazon-ssm-agent.log"
  }
}

resource "aws_cloudwatch_log_group" "ecs-agent" {
  name              = "/var/log/ecs/ecs-agent.log"
  retention_in_days = 1

  tags {
    Log = "/var/log/ecs/ecs-agent.log"
  }
}
