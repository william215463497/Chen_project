from nilearn.maskers import NiftiMasker
from nilearn import image
import numpy as np
import sys
from nilearn.image import math_img



seed_file = sys.argv[1]
brain_file = sys.argv[2]
output_filename = sys.argv[3]
c1_file = sys.argv[4]

# 2. 將機率圖二值化 (這裡設定閾值為 0.2，你可以根據需求調整為 0.3 或 0.5)
# math_img 會自動回傳一個已經二值化好的 Nifti1Image 記憶體物件
binary_gm_mask = math_img('img > 0.2', img=c1_file)



brain_masker = NiftiMasker(mask_img=binary_gm_mask, standardize='zscore_sample', detrend=False)
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