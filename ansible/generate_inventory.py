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
