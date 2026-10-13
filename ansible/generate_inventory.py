#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INVENTORY = ROOT / "ansible" / "inventory" / "hosts.ini"

result = subprocess.run(
    ["terraform", "-chdir=terraform", "output", "-json"],
    cwd=ROOT,
    check=True,
    capture_output=True,
    text=True,
)
outputs = json.loads(result.stdout)

def output(name):
    return outputs[name]["value"]

content = f"""# AWS_INFRASTRUCTURE_RECREATED_AND_INVENTORY_UPDATED
[jenkins]
jenkins-ec2 ansible_host={output("jenkins_public_ip")}

[web]
web-ec2 ansible_host={output("web_public_ip")}

[odoo]
odoo-ec2 ansible_host={output("odoo_public_ip")} private_ip={output("odoo_private_ip")}
"""

INVENTORY.write_text(content)
print(f"Inventaire Ansible généré : {INVENTORY}")
print(content, end="")

# Met à jour releases.txt avec les nouvelles IP (la ligne VERSION est conservée)
RELEASES = ROOT / "releases.txt"
new_lines = []
for line in RELEASES.read_text().splitlines():
    if line.startswith("ODOO_URL"):
        line = f"ODOO_URL http://{output('odoo_public_ip')}:8069"
    elif line.startswith("PGADMIN_URL"):
        line = f"PGADMIN_URL http://{output('web_public_ip')}:8081"
    new_lines.append(line)
RELEASES.write_text("\n".join(new_lines) + "\n")
print(f"releases.txt mis à jour : {RELEASES}")
