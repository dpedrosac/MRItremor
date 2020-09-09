import os
import ants
import glob
import subprocess


test_folder = ""

# Start with general commands
if os.getlogin() == 'david':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, 'data/patients/',
                               '4701P')  # this is going to be the subject used to test all the scripts

elif os.gelogin() == 'Kavi Karan':
    rootdir = os.getcwd()
    test_folder = os.path.join(rootdir, 'data/patients/', '4701P')

t2image = glob.glob(os.path.join(test_folder, '*t2*.nii.gz'))

# Import files into ants
test_data = ants.image_read(t2image[0])

# Display images in itksnap, if installed
cmd = ["itksnap", "-g", t2image[0]]

p = subprocess.Popen(cmd, shell=False,
                     stdin=subprocess.PIPE,
                     stdout=subprocess.DEVNULL,
                     stderr=subprocess.PIPE)
stdoutdata, stderrdata = p.communicate()
flag = p.returncode
if flag != 0:
    print(stderrdata)
