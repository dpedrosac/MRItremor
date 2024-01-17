#!/bin/bash
# author: David Pedrosa
# version: 2022-16-07, modified 2022-28-10 # fine-tuning of code
# script creating entire tractogram for all subjects after preprocessing using 
# the MRITRIX3 pipeline (cf. ./bash/preprocess_pipeline.sh)
# cf. https://www.youtube.com/channel/UCh9KmApDY_z_Zom3x9xrEQw


CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here
export FREESURFER_HOME=/opt/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/media/exthd3/freesurfer/

if [[ ! -d $SUBJECTS_DIR ]]; # create folder if not present
then
	mkdir -p $SUBJECTS_DIR
fi

## In case only some participants are wanted, use this snippet: rawdata/{3011S,4699S,4723S,4858S}  
echo
echo "======================================================================"
echo " Running tckgen for all subjects ... "
echo

for_each -nthreads 10 rawdata/* : tckgen -act IN/5tt_coreg.mif \
-backtrack -seed_gmwmi IN/gmwmSeed_coreg.mif \
-nthreads 40 \
-maxlength 250 \
-cutoff 0.06 \
-select 10000000 IN/wmfod_norm.mif IN/tracks_10M.tck -force

echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running tckedit for all subjects ... "
echo
for_each -nthreads 20 rawdata/* : tckedit IN/tracks_10M.tck \
-number 200k IN/smallerTracks_200k.tck  -force
echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running tcksift2 for all subjects ... "
echo
for_each -nthreads 20 rawdata/* : tcksift2 -act IN/5tt_coreg.mif \
-out_mu IN/sift_mu.txt \
-out_coeffs IN/sift_coeffs.txt \
 IN/tracks_10M.tck IN/wmfod_norm.mif IN/sift_1M.txt -force
echo
echo "Done!"
echo "======================================================================"
echo

echo
echo "======================================================================"
echo " Running recon-all for all subjects ... "
echo
for_each -nthreads 40 ./rawdata/* : recon-all -i IN/*MDEFT*.nii.gz -s PRE -all # {3011S,4699S,4723S,4858S}
echo
echo "Done!"
echo "======================================================================"
echo
