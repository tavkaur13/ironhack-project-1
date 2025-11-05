#!/bin/bash
set -e  # exit if any command fails

# Step 1: Terraform
echo "Applying Terraform to create infrastructure"
terraform init
terraform plan
terraform apply -auto-approve
sleep 10
echo ""
echo ""
# Step 2: Extract outputs
echo "Generating Ansible inventory..."
terraform output -json > tf_outputs.json
echo "Here is the json file with public and private ips that will be given to ansible inventory file"
cat tf_outputs.json
sleep 10
echo ""
echo ""
# Extracting IPs
DB_IP=$(jq -r '.instance_private_ips_db.value' tf_outputs.json)
WORKER_IP=$(jq -r '.instance_private_ips_worker.value' tf_outputs.json)
PUBLIC_IP=$(jq -r '.instance_public_ips.value' tf_outputs.json)

# Verify
echo "The extracted IPs are as follows"
echo $DB_IP
echo $WORKER_IP
echo $PUBLIC_IP
sleep 10
echo ""
echo ""
echo "Here is the created config file in the .ssh folder"
sleep 10
echo ""
echo ""
cat > ~/.ssh/config <<EOF
# Bastion host
Host public-bastion
    HostName $PUBLIC_IP
    User ubuntu
    IdentityFile ~/.ssh/tavleen_project1.pem

# Private worker server
Host private-worker
    HostName $WORKER_IP
    User ubuntu
    ProxyJump public-bastion
    IdentityFile ~/.ssh/tavleen_project1.pem

# Private DB server
Host private-db
    HostName $DB_IP
    User ubuntu
    ProxyJump public-bastion
    IdentityFile ~/.ssh/tavleen_project1.pem
EOF
cat ~/.ssh/config
sleep 10
echo ""
echo ""
echo "The ansible inventory file is as follows"
cat myinventory.ini
sleep 10
echo ""
echo ""
echo ""
cat > VotingApplicationTavleen1.yml << EOF
---
- name: Install docker on all hosts and make ubuntu able to use docker without sudo
  hosts: all
  become: yes
  tasks:
    - name: Update apt package index
      ansible.builtin.apt:
        update_cache: yes

    - name: Install Docker if not present
      ansible.builtin.package:
        name: docker.io
        state: present

    - name: Add user to docker group
      ansible.builtin.user:
        name: ubuntu
        groups: docker
        append: yes

- name: Deploy Postgres on private-db
  hosts: private-db
  become: yes
  vars:
    postgres_password: "postgres"
  tasks:

    - name: Run Postgres container
      community.docker.docker_container:
        name: db
        image: docker.io/postgres:latest
        state: started
        restart_policy: always
        pull: yes
        env:
          POSTGRES_PASSWORD: "{{ postgres_password }}"
          POSTGRES_USER: "postgres"
        published_ports:
          - "5432:5432"
    - name: Wait for Postgres to be ready
      wait_for:
        host: "$DB_IP"
        port: "5432"
        delay: "5"
        timeout: "60"

- name: Deploy container on private-worker
  hosts: private-worker
  become: yes
  tasks:
    - name: Run worker container
      community.docker.docker_container:
        name: worker_app
        image: docker.io/tavkaur13/ironhackproject1:worker-app
        state: started
        restart_policy: always
        network_mode: host
        env:
          DB_HOST: "$DB_IP"   # private IP of the Postgres EC2
          DB_PORT: "5432"
          DB_USER: "postgres"
          DB_PASSWORD: "postgres"
          REDIS_HOST: "127.0.0.1" #local host to connect to redis
          REDIS_PORT: "6379"


    - name: Run Redis container
      community.docker.docker_container:
        name: redis
        image: docker.io/redis:latest
        state: started
        restart_policy: always
        pull: yes
        published_ports:
          - "6379:6379"

- name: Deploy containers on public-bastion host
  hosts: public-bastion
  become: yes
  tasks:
    - name: Run voting-app container
      community.docker.docker_container:
        name: voting_app
        image: docker.io/tavkaur13/ironhackproject1:voting-app
        state: started
        restart_policy: always
        ports:
          - "2000:80"
        env:
          REDIS_HOST: "$WORKER_IP"      # Private IP of EC2 running Redis
          REDIS_PORT: "6379"

    - name: Run result-app container
      community.docker.docker_container:
        name: result_app
        image: docker.io/tavkaur13/ironhackproject1:result-app
        state: started
        restart_policy: always
        ports:
          - "2001:80"
        env:
          PG_HOST: "$DB_IP"       # Private IP of EC2 with Postgres
          PG_PORT: "5432"
          PG_USER: "postgres"
          PG_PASSWORD: "postgres"
EOF
echo "The created ansible file is as follows"
cat VotingApplicationTavleen1.yml
echo ""
echo ""
sleep 20
echo "Running the playbook now"
echo ""
echo "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i myinventory.ini VotingApplicationTavleen1.yml"
echo ""
sleep 5
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i myinventory.ini VotingApplicationTavleen1.yml
