import nibabel as nib
import numpy as np
from nilearn import image
import sys

zmap_file = sys.argv[1]
seed_file = sys.argv[2]
output_filename = sys.argv[3]


zmap_img = image.load_img(zmap_file) 
seed_img = image.load_img(seed_file) 

zmap_data = zmap_img.get_fdata()
seed_data = seed_img.get_fdata()

mask_3d = (seed_data <= 0)
masked_zmap_data = zmap_data * mask_3d


new_img = nib.Nifti1Image(masked_zmap_data, zmap_img.affine, zmap_img.header)
new_img.to_filename(output_filename)