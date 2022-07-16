#!/bin/bash
# author: David Pedrosa
# version: 2022-29-04
# pipeline to preprocess MRI data. This is an attempt to use the for_each** functionality
# from the MRITRIX3 pipeline (cf. ./bash/preprocess_pipeline.sh)
# cf. https://www.youtube.com/channel/UCh9KmApDY_z_Zom3x9xrEQw


CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored here

echo "--------------------------------------------------------------------------------------"
echo " Apply basis function to DWI data ... "
echo

	for_each -nthreads 10 ./rawdata/* : dwi2fod msmt_csd IN/dwi_den_unring_eddycorr_unbiased.mif -mask IN/betmask.mif IN/wm.txt IN/wmfod.mif IN/gm.txt IN/gmfod.mif IN/csf.txt IN/csffod.mif
	for_each -nthreads 10 ./rawdata/* : mrconvert -coord 3 0 IN/wmfod.mif - | mrcat IN/csffod.mif IN/gmfod.mif - IN/vf.mif

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo

echo "--------------------------------------------------------------------------------------"
echo " Normalizing FODs ... "
echo

        for_each -nthreads 40 ./rawdata/* : mtnormalise IN/wmfod.mif IN/wmfod_norm.mif IN/csffod.mif IN/csffod_norm.mif -mask IN/betmask.mif 

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo

echo "--------------------------------------------------------------------------------------"
echo " Convert anatomical imaging and extract tissues (MRITRIX3) ... "
echo

        for_each -nthreads 20 ./rawdata/* : mrconvert IN/*MDEFT*.nii.gz IN/T1.mif -force
        for_each -nthreads 10 ./rawdata/* : 5ttgen fsl IN/T1.mif IN/5tt_nocoreg.mif -force

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo


echo "--------------------------------------------------------------------------------------"
echo "10. Mean b0 values"
echo

        for_each -nthreads 20 ./rawdata/* : dwiextract IN/dwi_den_unring_eddycorr_unbiased.mif - -bzero | mrmath - mean IN/mean_b0.mif -axis 3 # extract b0 images
        for_each -nthreads 20 ./rawdata/* : mrconvert IN/mean_b0.mif IN/mean_b0.nii.gz -force
        for_each -nthreads 20 ./rawdata/* : mrconvert IN/5tt_nocoreg.mif IN/5tt_nocoreg.nii.gz -force
        for_each -nthreads 20 ./rawdata/* : fslroi IN/5tt_nocoreg.nii.gz IN/5tt_vol0.nii.gz 0 1 # extract grey matter
        for_each -nthreads 20 ./rawdata/* : flirt -in IN/mean_b0.nii.gz -ref IN/5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat IN/diff2struct_fsl.mat # coregister anatomical and dwi data
        for_each -nthreads 20 ./rawdata/* : transformconvert IN/diff2struct_fsl.mat IN/mean_b0.nii.gz IN/5tt_nocoreg.nii.gz flirt_import IN/diff2struct_mrtrix.txt -force
        for_each -nthreads 20 ./rawdata/* : mrtransform IN/5tt_nocoreg.mif -linear IN/diff2struct_mrtrix.txt -inverse IN/5tt_coreg.mif -force
        for_each -nthreads 20 ./rawdata/* : 5tt2gmwmi IN/5tt_coreg.mif IN/gmwmSeed_coreg.mif -force

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo
