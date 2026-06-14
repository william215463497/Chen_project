
mask_hdr = spm_vol('/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses01/roi/rNTUSEC008ROI1.nii');          % 請替換成你的 ROI 路徑
mask_img = spm_read_vols(mask_hdr);

% 2. 讀取 4D EPI 的所有標頭檔資訊 (SPM 會自動解析出所有 Volumes)
epi_hdrs = spm_vol('/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses01/REST_SES01/arREST_REST_3.4x3.4x4_20220304142158_7.nii');        % 請替換成你的 EPI 路徑
nvols = length(epi_hdrs);

% 3. 複製標頭檔，準備給輸出的 4D 檔案使用
out_hdrs = epi_hdrs; 
out_filename = 'ROI1_REST.nii';      % 你想儲存的新 4D 檔名

% 4. 開始逐一時間點 (Volume) 處理
fprintf('開始套用 ROI... 總共 %d 個時間點\n', nvols);
for t = 1:nvols
    out_hdrs(t).fname = out_filename;

    epi_img = spm_read_vols(epi_hdrs(t));


    masked_img = epi_img .* mask_img;

    spm_write_vol(out_hdrs(t), masked_img);
end
fprintf('處理完成！\n');