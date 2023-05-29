#!/bin/bash

rm -rf ./.vault
mkdir ./.vault
cd ./.vault
ssh-keygen -t rsa -b 4096 -f ./cluster -N ""
cd ../

cd ./compute_env
terraform init
terraform apply -auto-approve

echo "Waiting for the instance to be ready...(5min)"
sleep 300


cd ../
cd machine_setup
ansible-playbook -i inventory.ini installation/playbook.yml
# ansible-playbook -i inventory.ini deploy/playbook.yml

