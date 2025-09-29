output "instance_public_ips" {
  description = "Public IP addresses of instances"
  value       = aws_eip.eips[*].public_ip
}
