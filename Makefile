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
ID:='baitbenchtf'
LOCATION:='eastus'
GROUP_NAME:="batch${ID}rg"
STORAGE_ACCOUNT_NAME:="batch${ID}st"
CONTAINER_NAME:="batch${ID}container"
FILESHARE_NAME:="batch2${ID}share"
VM_SIZE:=Standard_NC24rs_v3
NUM_NODES:=2
CLUSTER_NAME:=tfbaitbench
JOB_NAME:=tf_benchmark
MODEL=resnet50
image_name=masalvar/batchai-tf-benchmark:9-1.8-0.13.2 # CUDA - Tensorflow - Horovod


 parser.add_argument('docker_image', type=str,
                        help='docker image to use')
    parser.add_argument('mpi', type=str,
                        help='mpi to use, must be install in the docker image provided options:[intelmpi, openmpi]')
    parser.add_argument('--filename', '-f', dest='filename', type=str, nargs='?',
                        default='job.json',
                        help='name of the file to save job spec to')
    parser.add_argument('--node_count', '-n', dest='node_count', type=int, nargs='?',
                        default=1, help='the number of nodes to run the job across')
    parser.add_argument('--model', '-m', dest='model', type=str, nargs='?',
                        default='resnet50',
                        help='the model to use')

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
	docker run -it $(image_name)

run-bash:
	docker run -it $(image_name) bash

push:
	docker push $(image_name)


select-subscription:
	az login -o table
	az account set --subscription "$(SELECTED_SUBSCRIPTION)"

create-storage:
	@echo "Creating storage account"
	az group create -n $(GROUP_NAME) -l $(LOCATION) -o table
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

create-cluster:
	az batchai cluster create
	--name ${tfbaitbench} \
	--image UbuntuLTS \
	--vm-size %{VM_SIZE} \
	--min ${NUM_NODES} --max ${NUM_NODES} \
	--afs-name ${FILESHARE_NAME} \
	--afs-mount-path extfs \
	--user-name mat \
	--password dnstvxrz \
	--storage-account-name $STORAGE_ACCOUNT_NAME \
	--storage-account-key $storage_account_key

show-cluster:
	az batchai cluster show -n ${CLUSTER_NAME}

list-clusters:
	az batchai cluster list -o table

list-nodes:
	az batchai cluster list-nodes -n ${CLUSTER_NAME} -o table

run-bait-intel:
	$(call generate_job_intel, )
	az batchai job create -n ${JOB_NAME} --cluster-name ${CLUSTER_NAME} -c job.json

run-bait-openmpi:
	$(call generate_job_openmpi, )
	az batchai job create -n ${JOB_NAME} --cluster-name ${CLUSTER_NAME} -c job.json

list-jobs:
	az batchai job list -o table

list-files:
	az batchai job list-files --name ${JOB_NAME} --output-directory-id stdouterr

stream-stdout:
	az batchai job stream-file --job-name ${JOB_NAME} --output-directory-id stdouterr --name stdout.txt

stream-stderr:
	az batchai job stream-file --job-name ${JOB_NAME} --output-directory-id stdouterr --name stderr.txt

delete-job:
	az batchai job delete --name --job-name ${JOB_NAME} -y

delete-cluster:
	az configure --defaults group=''
	az configure --defaults location=''
	az batchai cluster delete --name ${CLUSTER_NAME} -g ${GROUP_NAME} -y
	az group delete --name ${GROUP_NAME} -y

.PHONY: help build push
