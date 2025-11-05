# outputs.tf

output "instance_public_ips" {
  description = "Public IP addresses of the public EC2 instance in public subnet"
  value       = aws_instance.frontend.public_ip
}

output "instance_private_ips_worker" {
  description = "Private IP addresses of the EC2 instance in worker subnet"
  value       = aws_instance.private_ec2_worker.private_ip
}

output "instance_private_ips_db" {
    description = "Private IP addresses of the EC2 instance in db subnet"
    value       = aws_instance.private_ec2_db.private_ip
}
