#!/bin/bash
# author: David Pedrosa
# version: 2022-19-10 # changed the way registration is performed fundamentally; i.e. after using registration dwi2T1 at earlier stage.
# pipeline to preprocess MRI data. This is an attempt to use the for_each** functionality
# from the MRITRIX3 pipeline (cf. ./bash/preprocess_pipeline.sh)
# cf. https://www.youtube.com/channel/UCh9KmApDY_z_Zom3x9xrEQw


CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all general settings are stored in this directory

echo "--------------------------------------------------------------------------------------"
echo "9. Apply basis function to DWI data ... "
echo

	for_each -nthreads 20 ./rawdata/* : dwi2fod msmt_csd IN/dwi_den_unring_eddycorr_unbiased_coreg.mif \
	-mask IN/betT1.nii.gz IN/wm.txt IN/wmfod.mif IN/gm.txt IN/gmfod.mif IN/csf.txt IN/csffod.mif -nthreads 10 -force

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo


##	for_each -nthreads 20 ./rawdata/* : mrconvert -coord 3 0 IN/wmfod.mif - | mrcat IN/csffod.mif IN/gmfod.mif - IN/vf.mif -force



function_mrconvert() # function to merge all independent dwi sequences to one
{
	mrconvert -coord 3 0 $1/wmfod.mif - | mrcat $1/csffod.mif $1/gmfod.mif - $1/vf.mif -force
}

echo "================================================================"
echo "10. mrconvert all 'fod'-files"
echo

num_processes=20
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running mrconvert at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"
	function_mrconvert ${WORKING_DIR} & 
done
wait

echo "          ...done converting (MRTIX) for all subjects. Please perform visual checks"
echo
echo "================================================================"



echo "--------------------------------------------------------------------------------------"
echo "11. Normalizing FODs ... "
echo

        for_each -nthreads 20 ./rawdata/* : mtnormalise IN/wmfod.mif IN/wmfod_norm.mif IN/csffod.mif IN/csffod_norm.mif -mask IN/betT1.nii.gz -force 

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo

echo "--------------------------------------------------------------------------------------"
echo "12. Convert anatomical imaging and extract tissues (MRITRIX3) ... "
echo

        for_each -nthreads 20 ./rawdata/* : mrconvert IN/*MDEFT*.nii.gz IN/T1.mif -force
        for_each -nthreads 20 ./rawdata/* : 5ttgen fsl IN/T1.mif IN/5tt_coreg.mif -force

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo


echo "--------------------------------------------------------------------------------------"
echo "13. Mean b0 values" # commented out steps to normalise T1 to DWI, since not needed anymore after performing this step at the end of dwi preprocessing
echo

        for_each -nthreads 20 ./rawdata/* : dwiextract IN/dwi_den_unring_eddycorr_unbiased_coreg.mif - -bzero | mrmath - mean IN/mean_b0.mif -axis 3 # extract b0 images
        for_each -nthreads 20 ./rawdata/* : mrconvert IN/mean_b0.mif IN/mean_b0.nii.gz -force
        for_each -nthreads 20 ./rawdata/* : mrconvert IN/5tt_coreg.mif IN/5tt_coreg.nii.gz -force
        for_each -nthreads 20 ./rawdata/* : fslroi IN/5tt_coreg.nii.gz IN/5tt_vol0.nii.gz 0 1 # extract grey matter
#        for_each -nthreads 20 ./rawdata/* : flirt -in IN/mean_b0.nii.gz -ref IN/5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat IN/diff2struct_fsl.mat # coregister anatomical and dwi data
#        for_each -nthreads 20 ./rawdata/* : transformconvert IN/diff2struct_fsl.mat IN/mean_b0.nii.gz IN/5tt_nocoreg.nii.gz flirt_import IN/diff2struct_mrtrix.txt -force
#        for_each -nthreads 20 ./rawdata/* : mrtransform IN/5tt_nocoreg.mif -linear IN/diff2struct_mrtrix.txt -inverse IN/5tt_coreg.mif -force
        for_each -nthreads 20 ./rawdata/* : 5tt2gmwmi IN/5tt_coreg.mif IN/gmwmSeed_coreg.mif -force

echo
echo "Done!"
echo "--------------------------------------------------------------------------------------"
echo
