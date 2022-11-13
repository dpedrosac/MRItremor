#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07, modified 2022-26-08
# script getting the tracts for the ROI (VLp + Dentate nucleus bilaterally)

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

echo
echo "======================================================================"
echo " Obtaining tracts for all four cebellar and thalamic regions within all subjects ... part 1 "
echo

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_VLp.tck
echo

echo " ... part 2 (Thalamus)"

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_VLp.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 15 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_VLp.tck

echo
echo " ... part 3 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Left_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 15 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Left_Dentate.tck
echo

echo " ... part 4 (Cerebellum) "

for_each -nthreads 4 ./freesurfer/* : tckgen -act ${CURRENT_DIR}/rawdata/NAME/5tt_coreg.mif \
-backtrack -seed_image ${CURRENT_DIR}/freesurfer/NAME/mri/Right_Dentate.mgz \
-maxlength 250 \
-cutoff 0.06 \
-nthreads 10 \
-select 10000000 ${CURRENT_DIR}/rawdata/NAME/wmfod_norm.mif ${CURRENT_DIR}/rawdata/NAME/tracks_10M_Right_Dentate.tck
echo
echo "Done!"
echo "======================================================================"
echo
