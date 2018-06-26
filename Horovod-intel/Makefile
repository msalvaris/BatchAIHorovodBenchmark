define PROJECT_HELP_MSG
Usage:
    make help                   show this message
    make build                  make Horovod Keras image with Open MPI
    make build-intel            make Horovod Keras image with Intel MPI
    make run-mpi				run training using Open MPI image
    make run-mpi-intel			run training using Intel MPI image
    make run					run training in non-distributed mode
    make push					push Horovod Keras image with Open MPI
    make push-intel				push Horovod Keras image with Intel MPI
endef
export PROJECT_HELP_MSG

DATA_DIR:=/mnt/imagenet
PWD:=$(shell pwd)
numproc:=2
model:=resnet101

setup_volumes:=-v $(PWD)/src/execution:/mnt/script \
	-v $(DATA_DIR):/mnt/input \
	-v $(DATA_DIR)/temp/model:/mnt/model \
	-v $(DATA_DIR)/temp/output:/mnt/output


setup_environment:=--env AZ_BATCHAI_INPUT_TRAIN='/mnt/input/train' \
	--env AZ_BATCHAI_INPUT_TEST='/mnt/input/test' \
	--env AZ_BATCHAI_OUTPUT_MODEL='/mnt/model' \
	--env AZ_BATCHAI_JOB_TEMP_DIR='/mnt/output'

name_prefix:=masalvar
tag:=9-1.8-.13.2-dev # Cuda - TF version - Horovod version

define execute_mpi
 nvidia-docker run -it \
 --privileged \
 $(1) bash -c "mpirun -n $(numproc) -host localhost -ppn $(numproc) -env NCCL_DEBUG=INFO -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 \
 			   -envlist LD_LIBRARY_PATH,PATH \
 			   python scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model $(model) --batch_size 64 --variable_update horovod"
endef

#mpirun -np 16 \
#    -H server1:4,server2:4,server3:4,server4:4 \
#    -bind-to none -map-by slot \
#    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x PATH \
#    -mca pml ob1 -mca btl ^openib \
#    \
#    python scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py \
#        --model resnet101 \
#        --batch_size 64 \
#        --variable_update horovod

#define execute_mpi_intel
# nvidia-docker run -it \
# $(setup_volumes) \
# $(setup_environment) \
# --env DISTRIBUTED='True' \
# --env FAKE=$(FAKE) \
# --privileged \
# $(1) bash -c " source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh; mpirun -n 2 -host localhost -ppn 2 -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 python /mnt/script/ImagenetKerasHorovod.py"
#endef

help:
	echo "$$PROJECT_HELP_MSG" | less

build:
	docker build -t $(name_prefix)/horovod-batchai-bench-intel:$(tag) Docker

run-mpi:
	$(call execute_mpi, $(name_prefix)/horovod-batchai-bench-intel:$(tag))


push:
	docker push $(name_prefix)/horovod-batchai-bench-intel:$(tag)


.PHONY: help build push
