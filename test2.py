import os
# import ants
import glob
import subprocess
import getpass
import sys

from PyQt5.QtWidgets import QApplication, QLabel

from dependencies import ROOTDIR, CONFIGDATA
from utils.HelperFunctions import Output, Configuration, Imaging

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
Imaging.load_imageviewer(path2viewer=CONFIGDATA["folders"][getpass.getuser()]["path2itksnap"], file_names=t2image)

# Start loading data to Ants
