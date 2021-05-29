#!/bin/bash
# author: Irina Palaghia, Kavipiran Pavanandarajah
# version: 2021-05-29, modified 2021-05-29 by DP
# this script registers the processed images # for this purpose, FSL should be installed as described here:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation and folders MUST be adapted (FSLPATH)
# comments: nodif_brain=vol0000 bettted brain not mask! ref struc_T1=betted structural T1 image  reoriented_T1_whole_fov=whole T1 image nodif_brain_mask=vol0000 bettted brain mask

CURRENT_DIR=${PWD}
PARAMETER_DIR=${PWD}/bash/ # all settings for eddy are stored hree

export FSLDIR=/opt/FSL/
export PATH=$FSLDIR:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

function_registration()
{
echo "Now processing data at $1"
	if [[ ! -d $1/Registration ]];then
		mkdir -p $1/Registration
		chmod -R 777 $1/Registration
	fi

$FSLDIR/bin/flirt -in $1/bet_brain.nii.gz -ref $1/bet_brain_t1.nii.gz -omat $1/Registration/diff2str.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -cost corratio -v -out $1/Registration/flirted_nodif2struc

$FSLDIR/bin/convert_xfm -omat $1/Registration/str2diff.mat -inverse $1/Registration/diff2str.mat -v

$FSLDIR/bin/flirt -in $1/bet_brain_t1.nii.gz -ref $FSLDIR/data/standard/MNI152_T1_1mm_brain -omat $1/Registration/str2standard.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -cost corratio -v -out $1/Registration/flirted_struc2standard

$FSLDIR/bin/convert_xfm -omat $1/Registration/standard2str.mat -inverse $1/Registration/str2standard.mat -v

$FSLDIR/bin/convert_xfm -omat $1/Registration/diff2standard.mat -concat $1/Registration/str2standard.mat $1/Registration/diff2str.mat -v

$FSLDIR/bin/convert_xfm -omat $1/Registration/standard2diff.mat -inverse $1/Registration/diff2standard.mat -v

$FSLDIR/bin/fnirt --in=$1/struc_T1_whole.nii.gz --aff=$1/Registration/str2standard.mat --cout=$1/Registration/str2standard_warp --config=T1_2_MNI152_2mm -v --iout=$1/Registration/fNirted_struc2standard

$FSLDIR/bin/invwarp -w $1/Registration/str2standard_warp -o $1/Registration/standard2str_warp -r $1/bet_brain_t1.nii.gz -v

$FSLDIR/bin/convertwarp -o $1/Registration/diff2standard_warp -r $FSLDIR/data/standard/MNI152_T1_1mm -m $1/Registration/diff2str.mat -w $1/Registration/str2standard_warp -v

$FSLDIR/bin/convertwarp -o $1/Registration/standard2diff_warp -r $1/bet_brain_mask.nii.gz -w $1/Registration/standard2str_warp --postmat=$1/Registration/str2diff.mat -v

$FSLDIR/bin/applywarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm_brain --in=$1/bet_brain.nii.gz --out=$1/Registration/diffusionInMNI_CHECK.nii.gz --warp=$1/Registration/str2standard_warp.nii.gz --premat=$1/Registration/diff2str.mat

}

num_processes=4
for WORKING_DIR in ${CURRENT_DIR}/registrationBet/*/; do # runs eddy for every preprocessed subject
	((i=i%num_processes)); ((i++==0)) && wait
    	echo "======================================================================"
    	echo
    	echo "Running registration at $WORKING_DIR"
		function_registration $WORKING_DIR > $WORKING_DIR/log_Registration.txt &
done
wait
echo "          ...done with registration for all subjects. Please perform visual checks"
echo
echo "================================================================"
