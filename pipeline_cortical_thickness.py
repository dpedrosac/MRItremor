#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from utils.HelperFunctions import Configuration, Output, FileOperations, Imaging
from utils import MRI_BiasField as BiasFieldCorrection
from utils import BrainExtraction
from dependencies import FILEDIR, ROOTDIR

try:
    Imaging.set_viewer()
    print("viewer set!")
except Exception:
    Output.msg_box(text="Something went wrong with defining the standard location for ITK-snap!",
                   title="Problem defining ITKSnap location")

# Get files ready to analyse using the functions in the HelperFunctions.py module
subjects2analyse = list(FileOperations.list_folders(os.path.join(ROOTDIR, FILEDIR), prefix=''))
# BiasFieldCorrection.Correction().N4BiasSeq(subjects=subjects2analyse)
# BiasFieldCorrection.Correction().N4BiasMult(subjects=subjects2analyse)
BrainExtraction.AntsPyX().extract_list_of_patients(subjects=subjects2analyse)
