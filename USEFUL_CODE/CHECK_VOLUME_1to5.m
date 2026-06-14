nii_file = '/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses02/REST_SES02/arREST_REST_3.4x3.4x4_20220705150321_6.nii';

V = spm_vol(nii_file);
num_to_check = min(5, numel(V));
fprintf('\n=== 檢查 %s 的前 %d 個 Volumes 矩陣 ===\n', spm_file(nii_file, 'filename'), num_to_check);
% 執行迴圈列印
for i = 1:num_to_check
    % 完全複製 SPM 原廠的矩陣列印格式
    fprintf('Volume %d: [%g %g %g %g; %g %g %g %g; %g %g %g %g]\n',...
        i, V(i).mat(1:3,:)');
end
fprintf('==================================================\n\n');