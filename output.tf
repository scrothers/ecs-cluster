output "ecs_arn" {
  value = "${aws_ecs_cluster.cluster.arn}"
}

output "vpc_id" {
  value = "${aws_vpc.network.id}"
}

output "subnet_ids" {
  value = ["${aws_subnet.cluster_subnets.*.id}"]
}
