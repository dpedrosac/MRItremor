#!/bin/bash
# author: David Pedrosa
# version: 2022-29-04, $modification: changed mask name
# this script runs all the preprocessing steps for the MRTRIX3 pipeline
# cf. https://www.youtube.com/channel/UCh9KmApDY_z_Zom3x9xrEQw

function_fslmerge() # function to merge all independent dwi sequences to one
{
	ls $1/*diff*.nii.gz
	echo "======================================================================"

	fslmerge -a $1/diff_complete.nii.gz  $1/*diff*.nii.gz
}

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

echo "================================================================"
echo "1. Start concatenating images from nifti-output"
echo

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running fslmerge at multiple cores on $WORKING_DIR:"
	echo

	echo "Processing subj: ${WORKING_DIR##*/}"
	#function_fslmerge ${WORKING_DIR} ${PARAMETER_DIR} ${CURRENT_DIR} & 
done
wait

echo "          ...done merging (FSL) for all subjects. Please perform visual checks"
echo
echo "================================================================"



echo "================================================================"
echo "2. Convert images to mif-format and add (bvecs/bvals) information"
echo

function_mrconvert() # function to merge all independent dwi sequences to one
{
	echo "======================================================================"
	mrconvert $1/diff_complete.nii.gz -fslgrad $3/params/ep2d_diff_rolled.bvecs $3/params/ep2d_diff_rolled.bvals $1/dwi_raw.mif -force
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running mrconvert (MRITRIX3) at multiple cores on $WORKING_DIR:" # subj: ${dir##*/}"
	echo

	FILE=/${WORKING_DIR}/dwi_raw.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mrconvert ${WORKING_DIR} ${PARAMETER_DIR} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...done adding information from bval/bvec (MRITRIX) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "3. Denoise and preprocess data"
echo

function_mrpreprocess() # function to merge all independent dwi sequences to one
{
	
	OUTPUT_DIR=$1/eddy_output/
	if [[ ! -d $OUTPUT_DIR ]];
	then
		mkdir -p $OUTPUT_DIR
	fi
	
	dwidenoise $1/dwi_raw.mif $1/dwi_den.mif -force
	mrdegibbs $1/dwi_den.mif $1/dwi_den_unring.mif -axes 0,1 -force
	dwifslpreproc $1/dwi_den_unring.mif $1/dwi_den_unring_eddycorr.mif -rpe_none -pe_dir AP -readout_time 0.0889 -force -eddyqc_all ${OUTPUT_DIR} -eddy_options " --slm=linear --repol  --acqp=$3/params/acqparams.txt --cnr_maps --fwhm=0" 
	# dwifslpreproc dwi_raw.mif dwi_eddycorr.mif -rpe_none -pe_dir AP -readout_time 0.0889 -force -eddyqc_all ./ -eddy_options " --slm=linear --repol  --acqp=$3/params/acqparams.txt --cnr_maps --fwhm=0" 
}

num_processes=2
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwifslpreproc (MRITRIX3) at two cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/dwi_den_unring_eddycorr.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mrpreprocess ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi
done
wait

echo "          ...done denoising, 'deringing' and with eddy correction (MRITRIX/FSL) for all subjects"
echo
echo "================================================================"

# Sanity check for denoise (should be similar (identical?) to noise.mif):
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for residuals after denoise for subj:"
	dwidenoise ./rawdata/${SUBJ}/dwi_raw.mif ./rawdata/${SUBJ}/dwi_raw_den.mif
	mrcalc ./rawdata/${SUBJ}/dwi_raw.mif ./rawdata/${SUBJ}/dwi_raw_den.mif -subtract ./rawdata/${SUBJ}/residual.mif
	mrview ./rawdata/${SUBJ}/residual.mif
fi

echo "================================================================"
echo "4. Debias data"
echo

function_debias() # function to merge all independent dwi sequences to one
{
	dwibiascorrect ants $1/dwi_den_unring_eddycorr.mif $1/dwi_den_unring_eddycorr_unbiased.mif -bias $1/bias.mif -force
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwibiascorrect (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/dwi_den_unring_eddycorr_unbiased.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_debias ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done debiasting (MRITRIX/ANTs) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "5. Create mask"
echo

function_mask() # function to merge all independent dwi sequences to one
{
	dwi2mask $1/dwi_den_unring_eddycorr_unbiased.mif $1/betmask.mif -force
}

num_processes=1
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Running dwi2mask (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/betmask.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_mask ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...masks created (MRITRIX/ANTs) for all subjects"
echo
echo "================================================================"


# sanity check for debias:
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for masks and debiasing results"
	mrview ./rawdata/${SUBJ}/dwi_den_unring_eddycorr_unbiased.mif -overlay.load ./rawdata/${SUBJ}/betmask.mif
fi


echo "================================================================"
echo "6. Create basis model"
echo

function_msmt() # function to merge all independent dwi sequences to one
{
	dwi2response dhollander $1/dwi_den_unring_eddycorr_unbiased.mif $1/wm.txt $1/gm.txt $1/csf.txt -voxels $1/voxels.mif -nocleanup -scratch $1/
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Create MSMT (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/voxels.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_msmt ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "7. Apply basis function to DWI data"
echo

function_apply_basis_function() # function to merge all independent dwi sequences to one
{
	dwi2fod msmt_csd $1/dwi_den_unring_eddycorr_unbiased.mif -mask $1/betmask.mif $1/wm.txt $1/wmfod.mif $1/gm.txt $1/gmfod.mif $1/csf.txt $1/csffod.mif -force
	mrconvert -coord 3 0 $1/wmfod.mif - | mrcat $1/csffod.mif $1/gmfod.mif - $1/vf.mif -force
}

num_processes=2
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Create MSMT (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/wmfod.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_apply_basis_function ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"


# sanity check for viewing FODs:
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for creation of FODs"
	mrview ./rawdata/${SUBJ}/vf.mif -odf.load_sh ./rawdata/${SUBJ}wmfod.mif
fi


echo "================================================================"
echo "8. Normalizing the FODs"
echo

function_normalize_fods() # function to merge all independent dwi sequences to one
{
	mtnormalise $1/wmfod.mif $1/wmfod_norm.mif $1/csffod.mif $1/csffod_norm.mif -mask $1/betmask.mif -force 
	# because of single shell data, $1/gmfod.mif $1/gmfod_norm.mif were removed according to blog  
	# entry Error using mtnormalise in MRtrix3 blog 
}

num_processes=5
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Normalize FODs (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/wmfod_norm.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_normalize_fods ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"

echo "================================================================"
echo "9. Convert T1 and create five tissues"
echo

function_extractT1() # function to merge all independent dwi sequences to one
{
	mrconvert $1/*MDEFT*.nii.gz $1/T1.mif
	5ttgen fsl $1/T1.mif $1/5tt_nocoreg.mif -nthreads 6
}

num_processes=2
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Convert anatomical imaging and extract tissues (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/5tt_nocoreg.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_extractT1 ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"


echo "================================================================"
echo "10. Mean b0 values"
echo

function_preprocessT1()
{
	dwiextract $1/dwi_den_unring_eddycorr_unbiased.mif - -bzero | mrmath - mean $1/mean_b0.mif -axis 3 -force # extract b0 images
	mrconvert $1/mean_b0.mif $1/mean_b0.nii.gz -force
	mrconvert $1/5tt_nocoreg.mif $1/5tt_nocoreg.nii.gz -force
	fslroi $1/5tt_nocoreg.nii.gz $1/5tt_vol0.nii.gz 0 1 # extract grey matter
	#flirt -in $1/mean_b0.nii.gz -ref $1/5tt_vol0.nii.gz -interp nearestneighbour -dof 6 -omat $1/diff2struct_fsl.mat # coregister anatomical and dwi data
	flirt -in $1/mean_b0.nii.gz -ref $1/5tt_vol0.nii.gz -out -omat $1/diff2struct_fsl.mat -bins 256 -cost mutualinfo -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12  -interp trilinear
	transformconvert $1/diff2struct_fsl.mat $1/mean_b0.nii.gz $1/5tt_nocoreg.nii.gz flirt_import $1/diff2struct_mrtrix.txt -force
	mrtransform $1/5tt_nocoreg.mif -linear $1/diff2struct_mrtrix.txt -inverse $1/5tt_coreg.mif -force
	5tt2gmwmi $1/5tt_coreg.mif $1/gmwmSeed_coreg.mif -force
}

num_processes=1
for WORKING_DIR in ${PWD}/rawdata/*     # list directories in the form "/tmp/dirname/"
do
	((i=i%num_processes)); ((i++==0)) && wait
	echo "======================================================================"
	echo
	echo "Convert anatomical imaging and extract tissues (MRITRIX3) at several cores on $WORKING_DIR:"
	echo

	FILE=/${WORKING_DIR}/gmwmSeed_coreg.mif
	if [ -f "$FILE" ]; then
		echo "... subj: ${WORKING_DIR##*/} already processed!"
	else 
		echo "Processing subj: ${WORKING_DIR##*/}"
		function_preprocessT1 ${WORKING_DIR} ${WORKING_DIR##*/} ${CURRENT_DIR} & 
	fi

done
wait

echo "          ...done with modeling (MRITRIX) for all subjects"
echo
echo "================================================================"

# sanity check for viewing FODs:
FLAG_CHECK="FALSE"
SUBJ="3011S"
if [ "$FLAG_CHECK" = "TRUE" ]; then
	echo "Sanity check for coregistration"
	mrview ./rawdata/${SUBJ}/dwi_den_unring_eddycorr_unbiased.mif -overlay.load ./rawdata/${SUBJ}/5tt_nocoreg.mif -overlay.colourmap 2 -overlay.load ./rawdata/${SUBJ}/5tt_coreg.mif -overlay.colourmap 1
	mrview ./rawdata/${SUBJ}/dwi_den_unring_eddycorr_unbiased.mif -overlay.load ./rawdata/${SUBJ}/gmwmSeed_coreg.mif
fi