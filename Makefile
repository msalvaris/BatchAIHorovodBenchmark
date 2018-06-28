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

image_name=masalvar/batchai-tf-benchmark:1.8-9.0-0.13.2 # Tensorflow - CUDA - Horovod


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


.PHONY: help build push
