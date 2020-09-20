import os
# import ants
import glob
import subprocess
import getpass
from dependencies import ROOTDIR, CONFIGDATA
from utils.HelperFunctions import Output, Configuration, Imaging

try:
    Imaging.set_viewer()
except ValueError:
    Output.msg_box(text="Something went wrong with defining the standard location for ITK-snap!",
               title="Problem defining ITKSnap location")


# Start with general commands
if os.getlogin() == 'david':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, 'data/patients/',
                               '4701P')  # this is going to be the subject used to test all the scripts

elif os.getlogin() == 'Kavi Karan':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, 'data\\patients\\', '4701P')

t2image = glob.glob(os.path.join(test_folder, '*t2*.nii.gz'))

print(t2image)
Imaging.load_imageviewer(path2viewer=CONFIGDATA["folders"][getpass.getuser()]["path2itksnap"], file_names=t2image)

# Start loading data to Ants

