import os
import glob
import ants
import getpass

from PyQt5.QtWidgets import QApplication, QLabel
from utils.HelperFunctions import Output, Configuration, Imaging

from dependencies import ROOTDIR, CONFIGDATA

# define some useful direct paths from config
TEST_DATA_PATH = CONFIGDATA['folders'][getpass.getuser()]['testdata']
STANDARD_DATA_PATH = CONFIGDATA['folders'][getpass.getuser()]['standarddata']
OUTPUT_PATH = CONFIGDATA['folders'][getpass.getuser()]['outputpath']
ITKSNAP_LOCATION = CONFIGDATA['folders'][getpass.getuser()]['path2itksnap']
# print("test data path", TEST_DATA_PATH)

# lets create a new QApplication instance
app = QApplication([])

# ITK-SNAP viewer
try:
    Imaging.set_viewer()
except Exception:
    Output.msg_box(text="Something went wrong with defining the ITK-SNAP location.",
                   title="Problem defining ITK-SNAP location")

TEST_ROOT_FOLDER = f"{ROOTDIR}{TEST_DATA_PATH}"
STANDARD_DATA = f"{ROOTDIR}{STANDARD_DATA_PATH}"

FIXED = glob.glob(os.path.join(STANDARD_DATA, 'standard.nii'))
IMAGE1 = glob.glob(os.path.join(TEST_ROOT_FOLDER, '*bcorr*.nii.gz'))

print(FIXED)

fixed_image = ants.image_read(FIXED[0]).resample_image((200, 236, 50), True, 0)
moving_image = ants.image_read(IMAGE1[0]).resample_image((200, 236, 50), True, 0)

# moving_image.plot(axis=2)

fixed_image.plot(overlay=moving_image, title="Before Registration", axis=1, overlay_alpha=0.25)

#
mytx = ants.registration(fixed=fixed_image, moving=moving_image, type_of_transform='SyN')
print(mytx)
wrapped_image = mytx['warpedmovout']

fixed_image.plot(overlay=wrapped_image, title="After Registration", axis=1, overlay_alpha=0.25)

wrapped_image_output = ants.apply_transforms(fixed=fixed_image, moving=moving_image, transformlist=mytx['fwdtransforms'])

# wrapped_image_output.plot()
OUTPUT_FILE_PATH = f"{ROOTDIR}{OUTPUT_PATH}"
# ants.image_write(wrapped_image_output, os.path.join(OUTPUT_FILE_PATH, 'wrapped_img.nii'))
