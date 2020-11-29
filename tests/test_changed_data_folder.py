from dependencies import FILEDIR, ROOTDIR
import glob
import ants


TEMPLATE_PATH = f"{FILEDIR}/template"

prob_img = glob.glob(f"{FILEDIR}/template/*.nii")[0]

prob_mask = ants.image_read(prob_img)
mask = ants.threshold_image(prob_mask, 0.5, 1, 1, 0)
ants.plot(prob_img, mask)
ants.image_write(mask, f"{TEMPLATE_PATH}/mask.nii.gz")