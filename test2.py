import os
import ants
import glob

from PyQt5.QtWidgets import QApplication, QLabel

from utils.HelperFunctions import Output, Configuration, Imaging

# initializing a QT application instance
app = QApplication([])

try:
    Imaging.set_viewer()
    print("viewer set!")
except Exception:
    Output.msg_box(text="Something went wrong with defining the standard location for ITK-snap!",
                   title="Problem defining ITKSnap location")

# Start with general commands
if os.getlogin() == 'david':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, 'data/patients/',
                               '4701P')  # this is going to be the subject used to test all the scripts

# if the os.getlogin() is root, then that's mac, so we will find the username
# by using os.getevn("USER")
elif os.getlogin() == 'root':
    if os.getenv('USER') == 'kavikaran':
        rootdir = os.getcwd()
        test_folder = os.path.join(rootdir, 'data/patients', '4839P')
        print(test_folder)


t2image = glob.glob(os.path.join(test_folder, '*t2*.nii.gz'))
print(t2image)
exit()

if len(t2image) < 1:
    Output.msg_box(text="No files were found, please make sure only one file is present",
                   title="no files present")
elif len(t2image) > 1:
    Output.msg_box(text="Too many files were found, please make sure only one file is present",
                   title="too many files in the directory")

# print(t2image)
# Imaging.load_imageviewer(path2viewer=CONFIGDATA["folders"][getpass.getuser()]["path2itksnap"], file_names=t2image)

# ==============================          N4BiasCorrection          ==============================
# Start loading data to Ants
original_image = ants.image_read(t2image[0])

# ==============================          Rescale Images to positive values          ==============================
rescaler_nonneg = ants.contrib.RescaleIntensity(10, 100)  # to avoid values <0 causing problems w/ log data
min_orig, max_orig = original_image.min(), original_image.max()

rescale = True
if rescale:
    original_image_nonneg = rescaler_nonneg.transform(original_image)
else:
    original_image_nonneg = original_image

# ==============================          N4BiasCorrection          ==============================
# General settings
shrink_factor = 4
convergence = [50,50,50,50]
threshold = 1e-07
bspline_fitting = 200
filename_save_bcorr = 'bcorr-' + os.path.split(t2image[0])[1]
bcorr_image = ants.utils.n4_bias_field_correction(original_image_nonneg,
                                                  mask=None,
                                                  shrink_factor=shrink_factor,
                                                  convergence={'iters':convergence, 'tol': threshold},
                                                  spline_param=bspline_fitting, verbose=True)

ants.image_write(bcorr_image, filename=filename_save_bcorr)

filename_save_bcorrdiff = 'bcorr_diff-' + os.path.split(t2image[0])[1]
diff_image = original_image_nonneg - bcorr_image
ants.image_write(diff_image, filename=os.path.join(os.path.split(t2image[0])[0], filename_save_bcorrdiff))

