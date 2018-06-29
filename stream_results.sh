#!/usr/bin/env bash

make stream-stdout JOB_NAME=1gpulocal>1gpulocal_v100_local.results

make stream-stdout JOB_NAME=1gpuintel>1gpuintel_v100_intel.results
make stream-stdout JOB_NAME=2gpuintel>2gpuintel_v100_intel.results
make stream-stdout JOB_NAME=3gpuintel>3gpuintel_v100_intel.results
make stream-stdout JOB_NAME=4gpuintel>4gpuintel_v100_intel.results
make stream-stdout JOB_NAME=8gpuintel>8gpuintel_v100_intel.results

make stream-stdout JOB_NAME=1gpuopen>1gpuopen_v100_open.results
make stream-stdout JOB_NAME=2gpuopen>2gpuopen_v100_open.results
make stream-stdout JOB_NAME=3gpuopen>3gpuopen_v100_open.results
make stream-stdout JOB_NAME=4gpuopen>4gpuopen_v100_open.results
make stream-stdout JOB_NAME=8gpuopen>8gpuopen_v100_open.results
