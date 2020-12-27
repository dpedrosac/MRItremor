# These commands are needed to create a study specific template for the study; before running these commands,
# ANTS must be built according to https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS

# inputPath=${PWD}/rawdata/
# outputPath=${PWD}/template2/
# ${ANTSPATH}/antsMultivariateTemplateConstruction2.sh -d 3 -o ${outputPath}T_ -i 4 -g 0.15 -c 2 -k 1 -w 1 -f 8x4x2x1 -s 3x2x1x0 -q 100x70x50x10 -n 1 -r 1 -j 3 -m CC -t BSplineSyN[0.1,75,0]  ${inputPath}/*MDEFT3D.nii.gz > antsTemplateLog.txt 2>&1
