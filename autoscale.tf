data "aws_ami" "ecs-image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"]
}

resource "aws_launch_configuration" "ecs_configuration" {
  count             = "${length(var.instance-sizes)}"
  name_prefix       = "${var.environment}-${var.name}-${var.instance-sizes[count.index]}-lc-"
  image_id          = "${data.aws_ami.ecs-image.id}"
  instance_type     = "${var.instance-sizes[count.index]}"
  security_groups   = ["${aws_default_security_group.default.id}"]
  ebs_optimized     = false
  placement_tenancy = "default"
  user_data         = "${data.template_cloudinit_config.config.rendered}"
  key_name          = "scrothers"

  iam_instance_profile = "${aws_iam_instance_profile.ec2_profile.id}"

  root_block_device {
    volume_type           = "standard"
    volume_size           = 10
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdcz"
    volume_type           = "gp2"
    volume_size           = 32
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_configuration" {
  count                = "${length(var.instance-sizes)}"
  name_prefix          = "${var.environment}-${var.name}-${var.instance-sizes[count.index]}-asg-"
  desired_capacity     = 2
  max_size             = 2
  min_size             = 0
  launch_configuration = "${element(aws_launch_configuration.ecs_configuration.*.name, count.index)}"
  default_cooldown     = 60
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]
  health_check_type    = "EC2"

  vpc_zone_identifier = ["${aws_subnet.cluster_subnets.*.id}"]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment}-${var.name}-ecs-host"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = "${var.name}"
      propagate_at_launch = true
    },
    {
      key                 = "Application"
      value               = "ECS Cluster"
      propagate_at_launch = true
    },
    {
      key                 = "Launch Configuration"
      value               = "${element(aws_launch_configuration.ecs_configuration.*.name, count.index)}"
      propagate_at_launch = true
    },
    {
      key                 = "ECS Cluster"
      value               = "${aws_ecs_cluster.cluster.arn}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}
