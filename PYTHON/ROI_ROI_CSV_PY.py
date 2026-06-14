import sys
import pandas as pd
import numpy as np
import nibabel as nib
from sklearn.utils import Bunch
from nilearn.maskers import NiftiLabelsMasker
from nilearn.connectome import ConnectivityMeasure


my_func_files =sys.argv[1]                  #.nii.gz
my_confound_files = sys.argv[2]             #multiple_regressors_epi1
my_func_files = [my_func_files]
my_confound_files = [my_confound_files]

atlas_filepath = sys.argv[3]                #ATLAS
label_filepath = sys.argv[4]                #ATLAS.txt
save_name = sys.argv[5]                     #csv name

tr = 2.0 

###########################################
func_data = Bunch(
    func=my_func_files,
    confounds=my_confound_files,
    phenotypic= ['NONE'],
    description="func_data",
    t_r=tr
)

fmri_filepath = func_data.func[0]
###################################

labels = ['Background'] 

with open(label_filepath, 'r', encoding='utf-8') as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) >= 2:
            region_name = parts[1] 
            labels.append(region_name)
        elif len(parts) == 1:
            labels.append(parts[0])

masker = NiftiLabelsMasker(
    labels_img=atlas_filepath, 
    labels=labels, 
)

fmri_img = nib.load(fmri_filepath)
time_series = masker.fit_transform(fmri_img)

################################################

atlas_masker = NiftiLabelsMasker(labels_img=atlas_filepath)

data_in_atlas = atlas_masker.fit_transform(fmri_filepath)

########################################################


correlation_measure = ConnectivityMeasure(kind='correlation')
correlation_matrix = correlation_measure.fit_transform([data_in_atlas])[0]

np.fill_diagonal(correlation_matrix, 0)

########################################################


raw_labels_from_masker = np.array(masker.labels_).astype(int)
final_labels = raw_labels_from_masker[raw_labels_from_masker != 0]

print(f"✅ Masker 實際保留的有效腦區數量: {len(final_labels)}") 

num_extracted_regions = len(final_labels)

if correlation_matrix.shape[0] != num_extracted_regions:
    print(f"⚠️ 警告: 矩陣大小 ({correlation_matrix.shape[0]}) 與標籤數量 ({num_extracted_regions}) 不吻合！")
    print("這通常代表你在初始化 ConnectivityMeasure 或 NiftiLabelsMasker 時有其他設定介入。")
else:
    print("✅ 矩陣大小與標籤數量吻合，準備填入全矩陣。")


num_total_labels = 171 
full_correlation_matrix = np.zeros((num_total_labels, num_total_labels))
row_indices, col_indices = np.ix_(final_labels, final_labels)

full_correlation_matrix[row_indices, col_indices] = correlation_matrix

df_full_matrix = pd.DataFrame(
    full_correlation_matrix, 
    index=labels,      
    columns=labels   
)



df_full_matrix.to_csv(save_name, encoding='utf-8')
print("已成功儲存 171x171 的完整相關矩陣！")










