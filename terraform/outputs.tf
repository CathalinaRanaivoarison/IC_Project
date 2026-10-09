output "jenkins_public_ip" {
  description = "Public IP address of Jenkins"
  value       = aws_instance.jenkins.public_ip
}

output "web_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web.public_ip
}

output "odoo_public_ip" {
  description = "Public IP address of the Odoo server"
  value       = aws_instance.odoo.public_ip
}

output "odoo_private_ip" {
  description = "Private IP address of the Odoo server"
  value       = aws_instance.odoo.private_ip
}