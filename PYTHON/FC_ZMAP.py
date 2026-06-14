from nilearn.maskers import NiftiMasker
from nilearn import image
import numpy as np
import sys




seed_file = sys.argv[1]
brain_file = sys.argv[2]
output_filename = sys.argv[3]



brain_masker = NiftiMasker(mask_strategy='epi', standardize='zscore_sample', detrend=False)
seed_masker = NiftiMasker(standardize='zscore_sample', detrend=False)

brain_ts = brain_masker.fit_transform(brain_file) 
seed_ts = seed_masker.fit_transform(seed_file)

seed_1d = np.mean(seed_ts, axis=1)
seed_to_voxel_correlations = (np.dot(brain_ts.T, seed_1d) / seed_1d.shape[0])



###Z_MAP
seed_to_voxel_correlations = np.clip(seed_to_voxel_correlations, -0.999, 0.999) 
fisher_z_scores = np.arctanh(seed_to_voxel_correlations)
seed_to_voxel_ZZZ_correlations_img = brain_masker.inverse_transform(fisher_z_scores.T)
seed_to_voxel_ZZZ_correlations_img.to_filename(output_filename)