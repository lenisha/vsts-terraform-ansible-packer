#!/bin/bash

echo "************* set environment vars"
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_RESOURCE_GROUP=$3
export ARM_STORAGE_ACCOUNT=$4
export ARM_SUBSCRIPTION_ID=$5
export ARM_TENANT_ID=$6


rm packer-build-output.log
echo "************* execute packer build"
## execute packer build and sendout to packer-build-output file
packer build  -var playbook_drop_path=$7 ./app.json 2>&1 | tee packer-build-output.log

export manageddiskname=$(cat packer-build-output.log | grep ManagedImageName: | awk '{print $2}')

echo $manageddiskname
echo "##vso[task.setvariable variable=manageddiskname]$manageddiskname"