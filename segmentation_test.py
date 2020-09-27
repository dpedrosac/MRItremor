import ants

original = ants.image_read('original.nii.gz')
original.plot(title="original")


corrected = ants.image_read('biased_corrected.nii')
corrected.plot( title="bias corrected")

original.plot(overlay=corrected, title="overlayed image")