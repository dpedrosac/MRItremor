

# !/bin/bash
# this script runs the antsJointLabelFusion.sh script in order to get a majority voting scheme for the regions defined in the multiple atlases
# to run the script,  The THOMAS atlases for thalamic segmentations should be downloaded, ANTs be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR, OUTPUT_DIR, )

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
MALF_DIR=${PWD}/atlases/
OUTPUT_DIR=${PWD}/JLF_results_thalamus/

if [[ ! -d $OUTPUT_DIR ]];
  then
    echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
    mkdir -p $OUTPUT_DIR
  fi

echo "---------------------  Running Joint Label Fusion  ---------------------"

time_start=`date +%s`

TEMPLATE_BRAIN=${CURRENT_DIR}/SST/T_template0.nii.gz
IMG=${PWD}/MALF_templates/THOMAS2020/training-images/
IMGLABELS=${PWD}/MALF_templates/THOMAS2020/training-labels/


${ANTSPATH}antsJointLabelFusion.sh -d 3  -k 0 \
 -c 2 -j 3 \
 -o ${OUTPUT_DIR}ants \
 -x or \
 -p ${OUTPUT_DIR}Posteriors%02d.nii.gz \
 -t $TEMPLATE_BRAIN \
 -g ${IMG}ctrl1-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl1-Thomas-12_nuclei_atlas.nii.gz \
 -g ${IMG}ctrl2-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl2-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl3-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl3-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl4-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl4-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl5-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl5-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl6-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl6-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl7-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl7-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl8-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl8-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl9-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl9-Thomas-12_nuclei_atlas.nii.gz

time_end_jlfscript=`date +%s`
time_elapsed_jlf_script=$((time_end_jlfscript - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done with joint label fusion:  $(( time_elapsed_template_creation / 3600 ))h $(( time_elapsed_template_creation %3600 / 60 ))m $(( time_elapsed_template_creation % 60 ))s"
echo "--------------------------------------------------------------------------------------"
echo
