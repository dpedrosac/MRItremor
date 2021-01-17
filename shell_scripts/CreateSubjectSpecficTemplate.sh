#!/bin/bash
# this script intends to create a subject specific template (SST) which is intended to be used for all other steps
# for this purpose, ANTs should be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR)

export ANTSPATH=~/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
INPUT_DIR=${PWD}/raw_data/

${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
	   -d 3 \
	   -o ${outputPath}SST_MRITremor \
	   -i 4 \
	   -g 0.15\
	   -c 2 \
	   -k 1 \
	   -w 1 \
	   -f 8x4x2x1 \
	   -s 3x2x1x0 \
	   -q 100x70x50x10 \
	   -n 1 \
	   -r 1 \
	   -j 3 \
	   -m CC \
	   -t BSplineSyN[0.1,75,0] \
	   ${INPUT_PATH}*MDEFT3D.nii.gz > antsCreateSST.txt 2>&1
