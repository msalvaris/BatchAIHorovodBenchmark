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
 $(1) bash -c "mpirun -np $(numproc) -H localhost:$(numproc) -bind-to none \
 			   -map-by slot -x NCCL_DEBUG=INFO \
 			   -x LD_LIBRARY_PATH -x PATH \
 			    -mca pml ob1 -mca btl ^openib \
 			   python scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model $(model) --batch_size 64 --variable_update horovod"
endef

define execute
 nvidia-docker run -it \
 --privileged \
 $(1) bash -c "python scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --model $(model) --batch_size 64"
endef

help:
	echo "$$PROJECT_HELP_MSG" | less

build:
	docker build -t $(name_prefix)/horovod-batchai-bench:$(tag) Docker

run-mpi:
	$(call execute_mpi, $(name_prefix)/horovod-batchai-bench:$(tag))

run:
	$(call execute, $(name_prefix)/horovod-batchai-bench:$(tag))

push:
	docker push $(name_prefix)/horovod-batchai-bench:$(tag)


.PHONY: help build push
