#!/bin/bash
ls -la
echo "************* execute terraform apply  terraform apply -auto-approve -var manageddiskname=$6"

## execute terrafotm build and sendout to packer-build-output
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_SUBSCRIPTION_ID=$3
export ARM_TENANT_ID=$4
export ARM_ACCESS_KEY=$5

terraform apply -auto-approve -var "manageddiskname=$6"
terraform output vm_ip > inventory

##echo " ansible_user=azureuser" >> inventory