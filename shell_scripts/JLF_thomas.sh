# !/bin/bash
# this script runs the antsJointLabelFusion.sh script in order to get a majority voting scheme for the regions defined in the multiple atlases
# to run the script,  The THOMAS atlases for thalamic segmentations should be downloaded, ANTs be built from the source code, as described here:
# https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS and folders MUST be adapted (ANTSPATH, INPUT_DIR, OUTPUT_DIR, )

export ANTSPATH=/opt/ANTs/bin/
export PATH=${ANTSPATH}:$PATH

CURRENT_DIR=${PWD}
OUTPUT_DIR=${PWD}/JLF_thalamus_wnMPRAGE/

if [[ ! -d $OUTPUT_DIR ]];
  then
    echo "Output directory \"$OUTPUT_DIR\" does not exist. Creating it."
    mkdir -p $OUTPUT_DIR
  fi

TEMPLATE_BRAIN=${CURRENT_DIR}/SST/T_template0.nii.gz #${PWD}/templateThalamus.nii.gz
TEMPLATE_MASK =${CURRENT_DIR}/SST/T_template0BrainExtractionMask.nii.gz
IMG=${PWD}/MALF_templates/THOMAS2020/training-images/
IMGLABELS=${PWD}/MALF_templates/THOMAS2020/training-labels/

echo "---------------------  Register thalamic template to SST   ---------------------"
${ANTSPATH}antsRegistrationSyNQuick.sh -d 3 \
 -f ${PWD}/templateThalamus.nii.gz \
 -m $TEMPLATE_BRAIN \
 -o ${OUTPUT_DIR}/WarpedTemplate2WMnMPRAGE_ \
 -t a \
 -j 1

WARPED_TEMPLATE_BRAIN=${OUTPUT_DIR}/WarpedTemplate2WMnMPRAGE_InverseWarped.nii.gz

echo "---------------------  Running Joint Label Fusion  ---------------------"
time_start=`date +%s`

${ANTSPATH}antsJointLabelFusion.sh -d 3  -k 1 \
 -c 2 -j 2 \
 -q 1 \
 -p ${OUTPUT_DIR}Posteriors%02d.nii.gz \
 -t $WARPED_TEMPLATE_BRAIN \
 -o ${OUTPUT_DIR}ants_\
 -x or \
 -m "4gb" \
 -z "4gb" \
 -g ${IMG}ctrl1-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl1-Thomas-12_nuclei_atlas.nii.gz \
 -g ${IMG}ctrl2-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl2-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl3-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl3-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl4-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl4-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl5-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl5-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl6-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl6-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl7-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl7-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl8-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl8-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ctrl9-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ctrl9-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms1-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms1-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms2-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms2-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms3-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms3-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms4-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms4-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms5-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms5-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms6-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms6-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms7-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms7-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms8-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms8-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms9-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms9-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms10-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms10-Thomas-12_nuclei_atlas.nii.gz \
-g ${IMG}ms11-WMnMPRAGE_bias_corr.nii.gz -l ${IMGLABELS}ms11-Thomas-12_nuclei_atlas.nii.gz


time_end_jlfscript=`date +%s`
time_elapsed_jlf_script=$((time_end_jlfscript - time_start))

echo
echo "--------------------------------------------------------------------------------------"
echo " Done with joint label fusion:  $(( time_elapsed_template_creation / 3600 ))h $(( time_elapsed_template_creation %3600 / 60 ))m $(( time_elapsed_template_creation % 60 ))s"
echo "--------------------------------------------------------------------------------------"
echo
