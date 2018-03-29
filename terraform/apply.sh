#!/bin/bash
ls -la
echo "************* execute terraform apply"
## execute terrafotm build and sendout to packer-build-output
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_SUBSCRIPTION_ID=$3
export ARM_TENANT_ID=$4
export ARM_ACCESS_KEY=$5

terraform apply -auto-approve -var "baked_image_url=$6"
terraform output vm_ip > inventory

##echo " ansible_user=azureuser" >> inventory