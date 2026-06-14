% 1. 定義輸出的檔名與你想設定的 MNI 座標
output_name = 'mni_roi_mask.nii';
mni_coords = [
    21, -24, -12;   % 第一個點
    41,  21, -28;    % 第二個點
    21,-24,-28;
    10, 14, 12;
    34,-14,48
];

% 2. 讀取 SPM 內建的 TPM 影像作為空間幾何範本 (確保與 iy 的 MNI 空間完全一致)
%    如果是舊版 SPM，請將 'spm12' 改為對應路徑
tpm_path = fullfile(spm('Dir'), 'tpm', 'TPM.nii');
V_template = spm_vol([tpm_path ',1']); 

% 3. 初始化一個全為 0 的矩陣，大小與範本相同
img_data = zeros(V_template.dim);

% 4. 將 MNI 座標 (mm) 轉換為 Voxel 座標 (矩陣索引)
%    公式: Voxel = inv(V.mat) * [mm; 1]
inv_mat = inv(V_template.mat);

for i = 1:size(mni_coords, 1)
    % 轉換並四捨五入到最近的 Voxel 座標
    vox = inv_mat * [mni_coords(i, :), 1]';
    vox = round(vox(1:3))';
    
    % 安全檢查：確保座標在影像範圍內
    if all(vox >= 1) && all(vox <= V_template.dim)
        img_data(vox(1), vox(2), vox(3)) = 1;
    else
        warning('座標 (%d, %d, %d) 超出影像邊界！', mni_coords(i,:));
    end
end

% 5. 設定新影像的 Header 並寫入檔案
V_out = V_template;
V_out.fname = output_name;
V_out.dt    = [2 0]; % 設定為 uint8 (或 [16 0] float32)，節省空間且足夠裝 0 與 1
V_out.pinfo = [1; 0; 0]; % 重設 scaling factor

spm_write_vol(V_out, img_data);
disp(['成功建立影像：', output_name]);