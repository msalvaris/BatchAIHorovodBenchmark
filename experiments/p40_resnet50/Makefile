
PWD:=$(shell pwd)

# Variables for Batch AI - change as necessary
ID:=baitbenchtf
LOCATION:=eastus
GROUP_NAME:=batch${ID}rg
STORAGE_ACCOUNT_NAME:=batch${ID}st
CONTAINER_NAME:=batch${ID}container
FILE_SHARE_NAME:=batch2${ID}share
VM_SIZE:=Standard_ND24rs
NUM_NODES:=8
CLUSTER_NAME:=tfbaitbench
JOB_NAME:=tf_benchmark
MODEL:=resnet50
SELECTED_SUBSCRIPTION:="Team Danielle Internal"
WORKSPACE:=workspace
EXPERIMENT:=experimentp40
PROCESSES_PER_NODE:=4
GPU_TYPE:=p40

include ../include/*.mk
