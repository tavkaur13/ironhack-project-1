#!/bin/bash
set -e  # exit if any command fails

# Step 1: Terraform
echo "Applying Terraform to create infrastructure"
terraform init
terraform plan
terraform apply -auto-approve

# Step 2: Extract outputs
echo "Generating Ansible inventory..."
terraform output -json > tf_outputs.json
echo "Here is the json file with public and private ips that will be given to ansible inventory file"
cat tf_outputs.json
sleep 10

# Public EC2s
jq -r '.public_ec2_ips.value[]' tf_outputs.json | awk '{print "[public]\n"$1}' > inventory.ini

# Private EC2s
jq -r '.private_worker_ips.value[]' tf_outputs.json | awk '{print "[private_worker]\n"$1}' >> inventory.ini
jq -r '.private_db_ips.value[]' tf_outputs.json | awk '{print "[private_db]\n"$1}' >> inventory.ini
echo "Here is the created inventory file"
cat inventory.ini
