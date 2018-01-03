data "aws_iam_policy_document" "ecs_instance_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:Poll",
      "ecs:DiscoverPollEndpoint",
      "ecs:StartTelemetrySession",
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2messages:*",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstanceStatus",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.dmesg.arn}",
      "${aws_cloudwatch_log_group.dmesg.arn}/*",
      "${aws_cloudwatch_log_group.docker.arn}",
      "${aws_cloudwatch_log_group.docker.arn}/*",
      "${aws_cloudwatch_log_group.ssm-agent.arn}",
      "${aws_cloudwatch_log_group.ssm-agent.arn}/*",
      "${aws_cloudwatch_log_group.ecs-agent.arn}",
      "${aws_cloudwatch_log_group.ecs-agent.arn}/*",
      "${aws_cloudwatch_log_group.messages.arn}",
      "${aws_cloudwatch_log_group.messages.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:SubmitTaskStateChange",
      "ecs:RegisterContainerInstance",
      "ecs:SubmitContainerStateChange",
      "ecs:DeregisterContainerInstance",
    ]

    resources = [
      "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.environment}-${var.name}",
      "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.environment}-${var.name}/*",
    ]
  }
}

data "aws_iam_policy_document" "ec2_role_sts" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-${var.name}-ec2-role"
  path = "/${var.environment}/"

  description = "EC2 role for accessing the ${var.environment}-${var.name} ECS cluster."

  force_detach_policies = true

  assume_role_policy = "${data.aws_iam_policy_document.ec2_role_sts.json}"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.name}-ec2-profile"
  role = "${aws_iam_role.ec2_role.name}"
  path = "/${var.environment}/"
}

resource "aws_iam_role_policy" "ecs_instance_permissions" {
  name   = "${var.environment}-${var.name}-ecs_instance_permissions"
  role   = "${aws_iam_role.ec2_role.id}"
  policy = "${data.aws_iam_policy_document.ecs_instance_permissions.json}"
}
