define PROJECT_HELP_MSG
Usage:
    make help                   show this message
    make build                  build docker image
    make push					 push container
    make run					 run benchmarking container
    make setup                  setup the cluster
    make show-cluster
    make list-clusters
    make run-bait-intel         run batch ai benchamrk using intel mpi
    make run-bait-openmpi       run batch ai benchmark using open mpi
    make run-bait-local         run batch ai benchmark on one node
    make list-jobs
    make list-files
    make stream-stdout
    make stream-stderr
    make delete-job
    make delete-cluster
    make delete                 delete everything including experiments, workspace and resource group
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
PROCESSES_PER_NODE:=4

define generate_job_intel
 python generate_job_spec.py masalvar/horovod-batchai-bench-intel:9-1.8-0.13.2 intelmpi \
 	--filename job.json \
 	--node_count $(NUM_NODES) \
 	--model $(MODEL) \
 	--ppn $(PROCESSES_PER_NODE)
endef

define generate_job_openmpi
 python generate_job_spec.py masalvar/horovod-batchai-bench:9-1.8-0.13.2 openmpi \
 	--filename job.json \
 	--node_count $(NUM_NODES) \
 	--model $(MODEL) \
 	--ppn $(PROCESSES_PER_NODE)
endef


define generate_job_local
 python generate_job_spec.py masalvar/horovod-batchai-bench:9-1.8-0.13.2 local \
 	--filename job.json \
 	--node_count 1 \
 	--model $(MODEL) \
 	--ppn $(PROCESSES_PER_NODE)
endef

define stream_stdout
	az batchai job file stream -w $(WORKSPACE) -e $(EXPERIMENT) \
	--j $(1) --output-directory-id stdouterr -f stdout.txt
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
	az batchai experiment create -n $(EXPERIMENT) -g $(GROUP_NAME) -w $(WORKSPACE)

create-cluster: set-storage
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

run-bait-local:
	$(call generate_job_local, )
	az batchai job create -n ${JOB_NAME} --cluster ${CLUSTER_NAME} -w $(WORKSPACE) -e $(EXPERIMENT) -f job.json

list-jobs:
	az batchai job list -w $(WORKSPACE) -e $(EXPERIMENT) -o table

list-files:
	az batchai job file list -w $(WORKSPACE) -e $(EXPERIMENT) --j ${JOB_NAME} --output-directory-id stdouterr

stream-stdout:
	$(call stream_stdout, ${JOB_NAME})


stream-stderr:
	az batchai job file stream -w $(WORKSPACE) -e $(EXPERIMENT) --j ${JOB_NAME} --output-directory-id stdouterr -f stderr.txt

delete-job:
	az batchai job delete -w $(WORKSPACE) -e $(EXPERIMENT) --name ${JOB_NAME} -y

delete-cluster:
	az configure --defaults group=''
	az configure --defaults location=''
	az batchai cluster delete -w $(WORKSPACE) --name ${CLUSTER_NAME} -g ${GROUP_NAME} -y

delete: delete-cluster
	az batchai experiment delete -w $(WORKSPACE) --name ${experiment} -g ${GROUP_NAME} -y
	az batchai workspace delete -w ${WORKSPACE} -g ${GROUP_NAME} -y
	az group delete --name ${GROUP_NAME} -y


setup: select-subscription create-resource-group create-workspace create-storage set-storage set-az-defaults create-fileshare create-cluster list-clusters
	@echo "Cluster created"


1gpulocal_v100_local.results:
	$(call stream_stdout, 1gpulocal)>1gpulocal_v100_local.results

#
#make stream-stdout JOB_NAME=1gpulocal>
#
#make stream-stdout JOB_NAME=1gpuintel>1gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=2gpuintel>2gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=3gpuintel>3gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=4gpuintel>4gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=8gpuintel>8gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=16gpuintel>16gpuintel_v100_intel.results
#make stream-stdout JOB_NAME=32gpuintel>32gpuintel_v100_intel.results
#
#make stream-stdout JOB_NAME=1gpuopen>1gpuopen_v100_open.results
#make stream-stdout JOB_NAME=2gpuopen>2gpuopen_v100_open.results
#make stream-stdout JOB_NAME=3gpuopen>3gpuopen_v100_open.results
#make stream-stdout JOB_NAME=4gpuopen>4gpuopen_v100_open.results
#make stream-stdout JOB_NAME=8gpuopen>8gpuopen_v100_open.results
#make stream-stdout JOB_NAME=16gpuopen>16gpuopen_v100_open.results
#make stream-stdout JOB_NAME=32gpuopen>32gpuopen_v100_open.results

.PHONY: help build push
