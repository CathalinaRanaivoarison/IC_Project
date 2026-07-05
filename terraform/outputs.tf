output "jenkins_ip" { value = aws_instance.jenkins.public_ip }
output "webapp_ip"  { value = aws_instance.webapp.public_ip }
output "odoo_ip"    { value = aws_instance.odoo.public_ip }