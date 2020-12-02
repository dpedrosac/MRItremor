import os
import glob
import subprocess

subjects = []
t2images = []
patient_folders = []
test_folder = ""

# Start with general commands
if os.getlogin() == 'david':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, '../data/patients/',
                               '4701P')  # this is going to be the subject used to test all the scripts

elif os.getlogin() == 'Kavi Karan':
    rootdir = os.getcwd()

    subjects = os.listdir(os.path.join(rootdir, '../data', 'patients'))

    for item in subjects:
        patient_folders.append(os.path.join(rootdir, '../data', 'patients', f"{item}"))

for folder in patient_folders:
    t2images.append(glob.glob(os.path.join(folder, '*t2*.nii.gz'))[0])

for item in t2images:
    print(item)

print(len(t2images))