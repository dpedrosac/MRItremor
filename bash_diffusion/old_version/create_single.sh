#!/bin/bash
# author: David Pedrosa
# version: 2022-17-07
# script preprocessing thalamic and cerebellar ROIs before obtaining
# connectome using the MRITRIX3 routines
# cf. https://github.com/aaewarren/ESTEL-DBS/blob/b46b08efb1ecbd8a8780074b1861095d8b296a99/HCP_DBS_3.sh AND
##		https://neurobren.com/freesurfer-masks/

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

tckgen -act ${CURRENT_DIR}/rawdata/4735P/5tt_coreg.mif -backtrack -seed_image ${CURRENT_DIR}/freesurfer/4735P/mri/Left_VLp.mgz -maxlength 250 -cutoff 0.06 -nthreads 15 -select 10000000 ${CURRENT_DIR}/rawdata/4735P/wmfod_norm.mif ${CURRENT_DIR}/rawdata/4735P/tracks_10M_Left_VLp.tck -force -debug
