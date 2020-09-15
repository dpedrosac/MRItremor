import os
# import ants
import glob
import subprocess


test_folder = ""

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


