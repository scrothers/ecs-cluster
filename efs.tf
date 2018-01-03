resource "aws_efs_file_system" "ecs" {
  creation_token = "${var.environment}-${var.name}-efs"

  tags {
    Name        = "${var.environment}-${var.name}-efs"
    Cluster     = "${var.name}"
    Environment = "${var.environment}"
    Application = "ECS Cluster"
  }
}

resource "aws_efs_mount_target" "ecs" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  file_system_id = "${aws_efs_file_system.ecs.id}"
  subnet_id      = "${element(aws_subnet.cluster_subnets.*.id, count.index)}"
}
