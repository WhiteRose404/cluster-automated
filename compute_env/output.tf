output "public_ip" {
    description = "Public IP of the cluster instances"
    value = aws_instance.cluster.*.public_ip
}