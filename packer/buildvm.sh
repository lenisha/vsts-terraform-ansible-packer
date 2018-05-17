#!/bin/bash

echo "************* set environment vars"
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_SUBSCRIPTION_ID=$3
export ARM_TENANT_ID=$4
export ARM_RESOURCE_GROUP_DISKS=$5



rm packer-build-output.log
echo "************* execute packer build drop path $6"
## execute packer build and send out to packer-build-output file
packer build  -var playbook_drop_path=$6 ./app.json 2>&1 | tee packer-build-output.log

## export output variable to VSTS 
export manageddiskname=$(cat packer-build-output.log | grep ManagedImageName: | awk '{print $2}')

echo "variable $manageddiskname"
echo "##vso[task.setvariable variable=manageddiskname]$manageddiskname"

[ -z "$manageddiskname" ] && exit 1 || exit 0