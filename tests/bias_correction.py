import os
import glob
import ants
import getpass

from PyQt5.QtWidgets import QApplication, QLabel
from utils.HelperFunctions import Output, Configuration, Imaging

from dependencies import ROOTDIR, CONFIGDATA

print("root dir:", ROOTDIR)
# print("config data:", CONFIGDATA['folders']['kavikaran'])

# define some useful direct paths from config
TEST_DATA_PATH = CONFIGDATA['folders'][getpass.getuser()]['testdata']
ITKSNAP_LOCATION = CONFIGDATA['folders'][getpass.getuser()]['path2itksnap']
# print("test data path", TEST_DATA_PATH)

# lets create a new QApplication instance
app = QApplication([])

# ITK-SNAP viewer
viewer = None

try:
    viewer = Imaging.set_viewer()
except Exception:
    Output.msg_box(text="Something went wrong with defining the ITK-SNAP location.",
                   title="Problem defining ITK-SNAP location")

# load test patient data (4701P)
# it is a list of files
test_t2image = glob.glob(f"{ROOTDIR}{TEST_DATA_PATH}/*t2*.nii.gz")

# load the found image on itk-snap
# Imaging.load_imageviewer(path2viewer=ITKSNAP_LOCATION, file_names=test_t2image)

#
# N4BiasCorrection
#

# 1. open the image through ants lib
original_image = ants.image_read(test_t2image[0])
# print(original_image)
# print(original_image.min())
# print(original_image.max())

min_original, max_original = original_image.min(), original_image.max()

# 2. rescale image to positive values
rescaler_nonneg = ants.contrib.RescaleIntensity(10, 100)

rescale = True
if rescale:
    original_image_nonneg = rescaler_nonneg.transform(original_image)
else:
    original_image_nonneg = original_image

# print(original_image_nonneg)
# print(original_image_nonneg.min())
# print(original_image_nonneg.max())

# ants.plot(original_image, title="original")
# ants.plot(original_image_nonneg, title="nonneg")

# General settings for N4BiasCorrection
shrink_factor = 4
convergence = [50, 50, 50, 50]
threshold = 1e-07
bspline_fitting = 200

bias_corrected_image = ants.utils.n4_bias_field_correction(
    image=original_image_nonneg,
    mask=None,
    shrink_factor=shrink_factor,
    convergence={'iters': convergence, 'tol': threshold},
    spline_param=bspline_fitting,
    verbose=True
)

original_file_name = os.path.split(test_t2image[0])[1]
useful_part = original_file_name.split('_t2_')[0]
new_filename_bcorr = f"bcorr_{useful_part}.nii.gz"
new_filename_bcorr_diff = f"bc_diff_{useful_part}.nii.gz"
new_full_filename_bcorr = os.path.join(f"{ROOTDIR}{TEST_DATA_PATH}", new_filename_bcorr)
new_full_filename_bcorr_diff = os.path.join(f"{ROOTDIR}{TEST_DATA_PATH}", new_filename_bcorr_diff)

ants.image_write(bias_corrected_image, new_full_filename_bcorr)

diff_image = original_image_nonneg - bias_corrected_image
ants.image_write(diff_image, new_full_filename_bcorr_diff)
