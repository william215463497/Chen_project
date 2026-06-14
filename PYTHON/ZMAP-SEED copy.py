import nibabel as nib
import numpy as np
from nilearn import image
import sys

zmap_file = "/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses02/roi/roi1_HIP_R/NTUSEC008ZMAP2.nii"
seed_file = "/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses02/roi/roi1_HIP_R/rNTUSEC008ROI1.nii"
output_filename = "/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses02/roi/roi1_HIP_R/TEST.nii"


zmap_img = image.load_img(zmap_file) 
seed_img = image.load_img(seed_file) 

zmap_data = zmap_img.get_fdata()
seed_data = seed_img.get_fdata()

mask_3d = (seed_data <= 0)
masked_zmap_data = zmap_data * mask_3d


new_img = nib.Nifti1Image(masked_zmap_data, zmap_img.affine, zmap_img.header)
new_img.to_filename(output_filename)