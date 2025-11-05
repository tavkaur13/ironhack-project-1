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

# Extracting IPs
DB_IP=$(jq -r '.instance_private_ips_db.value' tf_outputs.json)
WORKER_IP=$(jq -r '.instance_private_ips_worker.value' tf_outputs.json)
PUBLIC_IP=$(jq -r '.instance_public_ips.value' tf_outputs.json)

# Verify
echo "The extracted IPs are as follows"
echo $DB_IP
echo $WORKER_IP
echo $PUBLIC_IP

echo "Here is the created inventory file"
cat > inventory.ini <<EOF
[voting_app]
$PUBLIC_IP

[worker]
$WORKER_IP

[db]
$DB_IP
EOF

