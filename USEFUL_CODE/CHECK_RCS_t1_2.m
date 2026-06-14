% 1. 彈出視窗，請全選您要檢查的所有影像 (例如所有 rc1 和 rc2)
P = spm_select(Inf, 'image', 'Select all images to check dimensions');

% 防呆機制：如果沒有選擇檔案就取消
if isempty(P)
    disp('未選擇任何檔案，操作取消。');
else
    % 2. 讀取所有影像標頭資訊
    V = spm_vol(P);

    % 3. 提取所有影像的維度矩陣
    dims = cat(1, V.dim);

    % 4. 找出獨特的維度種類，以及它們在原陣列中的索引
    [unique_dims, ~, idx] = unique(dims, 'rows');

    % 5. 印出統計結果
    fprintf('\n================ 維度檢查報告 ================\n');
    fprintf('總共檢查了 %d 張影像。\n', length(V));
    fprintf('發現 %d 種不同的影像維度：\n\n', size(unique_dims, 1));

    for i = 1:size(unique_dims, 1)
        % 計算該種維度的影像數量
        count = sum(idx == i);
        fprintf('▶ 維度類型 %d: [%3d, %3d, %3d] ➔ 共 %4d 張\n', ...
            i, unique_dims(i, 1), unique_dims(i, 2), unique_dims(i, 3), count);
    end
    fprintf('==============================================\n\n');

    % 6. (選用) 如果維度超過 1 種，列出少數派(可能有問題)的檔案名稱
    if size(unique_dims, 1) > 1
        disp('⚠️ 警告：發現多種維度！以下列出各維度對應的前幾個檔案以供檢查：');
        filenames = {V.fname}';
        for i = 1:size(unique_dims, 1)
            fprintf('\n[維度 %d x %d x %d] 的檔案包含:\n', unique_dims(i, 1), unique_dims(i, 2), unique_dims(i, 3));
            current_files = filenames(idx == i);
            % 為了避免洗版，每種維度最多只顯示 5 個檔名
            display_count = min(5, length(current_files));
            for j = 1:display_count
                fprintf('   - %s\n', current_files{j});
            end
            if length(current_files) > 5
                fprintf('   ... (還有 %d 張未顯示)\n', length(current_files) - 5);
            end
        end
    else
        disp('✅ 檢查通過：所有影像維度皆一致！');
    end
end