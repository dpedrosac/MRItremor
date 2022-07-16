 #!/bin/bash
#author: Irina Palaghia
#version: 21.04.2021
#this script performs:
#Merging and splitting of raw data

for dir in ~/Data_David_Pedrosa/patients/*/; do
	echo "$dir"
	cd "$dir"

	fslmerge -t merged_raw_dti_data *_j01.nii.gz *_j02.nii.gz *_j03.nii.gz *_j04.nii.gz *_j05.nii.gz *_j06.nii.gz
	mkdir split
	cp "$dir"/merged_raw_dti_data.nii.gz split
	cd split
	fslsplit merged_raw_dti_data.nii.gz

done

 echo "Merging and splitting done"
