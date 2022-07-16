 #!/bin/bash
#author: Irina Palaghia
#version: 21.04.2021


for dir in ~/Data_David_Pedrosa/patients/*/; do
	echo "$dir"
	cd "$dir"

	cp /home/parkinson_ag/Data_David_Pedrosa/acqparams.txt "$dir"
	cp /home/parkinson_ag/Data_David_Pedrosa/ep2d_diff_rolled.bvals "$dir"
	cp /home/parkinson_ag/Data_David_Pedrosa/ep2d_diff_rolled.bvecs "$dir"
	cp /home/parkinson_ag/Data_David_Pedrosa/index.txt "$dir"
	cp /home/parkinson_ag/Data_David_Pedrosa/slspec.txt "$dir"

	eddy_cuda --imain=merged_raw_dti_data.nii.gz --mask=bet_brain_mask.nii.gz --acqp=acqparams.txt --index=index.txt --bvecs=ep2d_diff_rolled.bvecs --bvals=ep2d_diff_rolled.bvals --repol --out=eddycorrected_data -v --fwhm=0 --repol --mporder=25 --estimate_move_by_susceptibility --slspec=slspec.txt --cnr_maps

done

 echo "eddy correction done, please perform visual checks"
