from dependencies import FILEDIR, ROOTDIR
import glob


print(FILEDIR)
print(ROOTDIR)

print(glob.glob(f"{FILEDIR}/*"))