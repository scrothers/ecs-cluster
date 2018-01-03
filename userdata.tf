# Template for initial configuration bash script
data "template_file" "userdata" {
  template = "${file("scripts/user-data.sh")}"

  vars {
    ECS_CLUSTER    = "${var.environment}-${var.name}"
    EFS_HOST       = "${aws_efs_file_system.ecs.dns_name}"
    REGION         = "${data.aws_region.current.name}"
    AWS-MON-SCRIPT = "${file("scripts/aws-mon.sh")}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/part-handler"
    content      = "${data.template_file.userdata.rendered}"
  }
}
