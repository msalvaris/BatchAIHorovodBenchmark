define PROJECT_HELP_MSG
Usage:
    make help                   show this message
    make build                  build docker image
    make push					push container
    make run					run benchmarking
    make clean
endef
export PROJECT_HELP_MSG


PWD:=$(shell pwd)

# Variables for Batch AI - change as necessary
ID:=baitbenchtf
LOCATION:=eastus
GROUP_NAME:=batch${ID}rg
STORAGE_ACCOUNT_NAME:=batch${ID}st
CONTAINER_NAME:=batch${ID}container
FILE_SHARE_NAME:=batch2${ID}share
VM_SIZE:=Standard_NC24rs_v3
NUM_NODES:=2
CLUSTER_NAME:=tfbaitbench
JOB_NAME:=tf_benchmark
MODEL:=resnet50
SELECTED_SUBSCRIPTION:="Team Danielle Internal"
image_name:=masalvar/batchai-tf-benchmark:9-1.8-0.13.2 # CUDA - Tensorflow - Horovod
WORKSPACE:=workspace
EXPERIMENT:=experiment

define generate_job_intel
 python generate_job_spec.py masalvar/horovod-batchai-bench-intel:9-1.8-0.13.2 intelmpi
 	--filename job.json
 	--node_count $(NUM_NODES)
 	--model $(MODEL)
endef

define generate_job_openmpi
 python generate_job_spec.py masalvar/horovod-batchai-bench:9-1.8-0.13.2 openmpi
 	--filename job.json
 	--node_count $(NUM_NODES)
 	--model $(MODEL)
endef


help:
	echo "$$PROJECT_HELP_MSG" | less

build:
	docker build -t $(image_name) Docker

run:
	docker run -v $(PWD):/workspace -it $(image_name) bash

push:
	docker push $(image_name)


select-subscription:
	az login -o table
	az account set --subscription $(SELECTED_SUBSCRIPTION)

create-resource-group:
	az group create -n $(GROUP_NAME) -l $(LOCATION) -o table

create-storage:
	@echo "Creating storage account"
	az storage account create -l $(LOCATION) -n $(STORAGE_ACCOUNT_NAME) -g $(GROUP_NAME) --sku Standard_LRS

set-storage:
	$(eval azure_storage_key:=$(shell az storage account keys list -n $(STORAGE_ACCOUNT_NAME) -g $(GROUP_NAME) | jq '.[0]["value"]'))
	$(eval azure_storage_account:= $(STORAGE_ACCOUNT_NAME))
	$(eval file_share_name:= $(FILE_SHARE_NAME))

set-az-defaults:
	az configure --defaults location=${LOCATION}
	az configure --defaults group=${GROUP_NAME}

create-fileshare: set-storage
	@echo "Creating fileshare"
	az storage share create -n $(file_share_name) --account-name $(azure_storage_account) --account-key $(azure_storage_key)

create-workspace:
	az batchai workspace create -n $(WORKSPACE) -g $(GROUP_NAME)

create-experiment:
	az batchai workspace create -n $(EXPERIMENT) -g $(GROUP_NAME) -w $(WORKSPACE)

create-cluster:
	az batchai cluster create \
	-w $(WORKSPACE) \
	--name ${CLUSTER_NAME} \
	--image UbuntuLTS \
	--vm-size ${VM_SIZE} \
	--min ${NUM_NODES} --max ${NUM_NODES} \
	--afs-name ${FILE_SHARE_NAME} \
	--afs-mount-path extfs \
	--user-name mat \
	--password dnstvxrz \
	--storage-account-name $(STORAGE_ACCOUNT_NAME) \
	--storage-account-key $(azure_storage_key)

show-cluster:
	az batchai cluster show -n ${CLUSTER_NAME} -w $(WORKSPACE)

list-clusters:
	az batchai cluster list -w $(WORKSPACE) -o table

list-nodes:
	az batchai cluster list-nodes -n ${CLUSTER_NAME} -w $(WORKSPACE) -o table

run-bait-intel:
	$(call generate_job_intel, )
	az batchai job create -n ${JOB_NAME} --cluster ${CLUSTER_NAME} -w $(WORKSPACE) -e $(EXPERIMENT) -f job.json

run-bait-openmpi:
	$(call generate_job_openmpi, )
	az batchai job create -n ${JOB_NAME} --cluster ${CLUSTER_NAME} -w $(WORKSPACE) -e $(EXPERIMENT) -f job.json

list-jobs:
	az batchai job list -w $(WORKSPACE) -e $(EXPERIMENT) -o table

list-files:
	az batchai job file list -w $(WORKSPACE) -e $(EXPERIMENT) --j ${JOB_NAME} --output-directory-id stdouterr

stream-stdout:
	az batchai job stream -w $(WORKSPACE) -e $(EXPERIMENT) --j ${JOB_NAME} --output-directory-id stdouterr -f stdout.txt

stream-stderr:
	az batchai job stream -w $(WORKSPACE) -e $(EXPERIMENT) --j ${JOB_NAME} --output-directory-id stdouterr -f stderr.txt

delete-job:
	az batchai job delete -w $(WORKSPACE) -e $(EXPERIMENT) --name ${JOB_NAME} -y

delete-cluster:
	az configure --defaults group=''
	az configure --defaults location=''
	az batchai cluster delete -w $(WORKSPACE) --name ${CLUSTER_NAME} -g ${GROUP_NAME} -y
	az batchai experiment delete -w $(WORKSPACE) --name ${experiment} -g ${GROUP_NAME} -y
	az batchai workspace delete -w ${WORKSPACE} -g ${GROUP_NAME} -y
	az group delete --name ${GROUP_NAME} -y

setup: select-subscription create-resource-group create-workspace create-storage set-storage set-az-defaults create-fileshare create-cluster list-clusters
	@echo "Cluster created"



.PHONY: help build push
