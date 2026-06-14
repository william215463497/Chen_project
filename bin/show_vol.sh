#!/bin/bash

# 檢查是否帶有輸入參數 (NIfTI 檔案路徑)
if [ -z "$1" ]; then
    echo "錯誤：請提供 NIfTI 檔案路徑。"
    echo "用法：$0 <nii_file_path>"
    exit 1
fi

# 取得輸入的檔案路徑
input_nii="${1}"

# 執行 MATLAB，使用 -nodisplay 等參數以純文字模式在背景執行
unset DISPLAY
matlab -nodisplay -nosplash -nodesktop << EOF

    % 若您的 SPM12 沒有在 MATLAB 的預設路徑中，請取消註解並修改以下這行：
    % addpath('/opt/spm'); 

    nii_file = '${input_nii}';
    
    try
        V = spm_vol(nii_file);
        num_to_check = min(3, numel(V));
        
        % 執行迴圈列印
        for i = 1:num_to_check
            % 完全複製 SPM 原廠的矩陣列印格式
            fprintf('Volume %d: [%g %g %g %g; %g %g %g %g; %g %g %g %g]\n',...
                i, V(i).mat(1:3,:)');
        end
        fprintf('==================================================\n\n');
    catch ME
        fprintf('\n[錯誤] 無法讀取檔案或發生例外狀況: %s\n\n', ME.message);
    end
    
    exit;
EOF