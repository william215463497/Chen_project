% 1. 在這裡輸入你的 5 個 MNI 座標點 (一行一個點)
mni_coords = [
    21, -24, -12;   % 第一個點
    41,  21, -28;    % 第二個點
    21,-24,-28;
    10, 14, 12;
    34,-14,48
];

% 2. 選擇基準影像 (確保大小對齊)
ref_file = spm_select(1, 'image', '請選取一張 MNI 空間的影像(如 w*.nii)');
V = spm_vol(ref_file);

% 3. 建立全黑(0)的空白大腦矩陣
img_data = zeros(V.dim);

% 4. 尋找座標並點亮(1)
for i = 1:size(mni_coords, 1)
    % 將 mm 轉為 Voxel 矩陣位置
    vox = V.mat \ [mni_coords(i, :), 1]';
    vox = round(vox(1:3));
    
    % 在該格子填入 1
    if all(vox >= 1) && all(vox' <= V.dim)
        img_data(vox(1), vox(2), vox(3)) = 1;
    end
end

% 5. 存檔輸出
V_new = V;
V_new.fname = 'my_perfect_5_points.nii'; % 輸出的檔名
V_new.dt = [2 0]; % uint8 格式
spm_write_vol(V_new, img_data);

disp('恭喜！5個點的完美影像已生成：my_perfect_5_points.nii');