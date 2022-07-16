 #!/bin/bash
#author: Irina Palaghia
#version: 21.04.2021


for dir in ~/Data_David_Pedrosa/patients/*/; do
	echo "$dir"
	cd "$dir"

	cp "$dir"split/vol0000.nii.gz "$dir"
	bet vol0000.nii.gz bet_brain -m -f 0.3

done

 echo "bet done, plese visually check brains and ajust -f if necessary"
