#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07
# script preprocessing thalamic segmentation in order to align it to DTI data

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

echo
echo "======================================================================"
echo " Aligning thalamic segmentation to DTI data... "
echo

for_each -nthreads 20 ./freesurfer/* : mrtransform ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz -reorient_fod no

for_each -nthreads 20 ./freesurfer/* : flirt -in ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.nii.gz \
-ref ${CURRENT_DIR}/rawdata/NAME/5tt_vol0.nii.gz \
-interp nearestneighbour \
-dof 6 \
-omat ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.mat

for_each -nthreads 20 ./freesurfer/* : transformconvert ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.mat \
${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif \
${CURRENT_DIR}/rawdata/NAME/5tt_vol0.nii.gz flirt_import ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.txt -force

for_each -nthreads 20 ./freesurfer/* : mrtransform ${CURRENT_DIR}/freesurfer/NAME/mri/ThalamicNuclei.v12.T1.mgz \
-linear ${CURRENT_DIR}/rawdata/NAME/thalamus2diff.txt -inverse ${CURRENT_DIR}/freesurfer/NAME/mri/ThalamicNuclei.v12.T1adapted.mif -force

echo
echo "Done!"
echo "======================================================================"
echo

