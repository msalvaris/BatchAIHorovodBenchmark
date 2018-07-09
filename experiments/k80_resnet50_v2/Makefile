
PWD:=$(shell pwd)

# Variables for Batch AI - change as necessary
ID:=baitbenchtf
LOCATION:=eastus
GROUP_NAME:=batch${ID}rg
STORAGE_ACCOUNT_NAME:=batch${ID}st
CONTAINER_NAME:=batch${ID}container
FILE_SHARE_NAME:=batch2${ID}share
VM_SIZE:=Standard_NC24r
NUM_NODES:=8
CLUSTER_NAME:=tfbaitbench
JOB_NAME:=tf_benchmark
MODEL:=resnet50_v2
SELECTED_SUBSCRIPTION:="Team Danielle Internal"
WORKSPACE:=workspace
GPU_TYPE:=k80
EXPERIMENT:=experiment_${GPU_TYPE}_${MODEL}
PROCESSES_PER_NODE:=4


include ../include/*.mk
