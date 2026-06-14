% 1. 彈出視窗，請全選您剛剛放入 DARTEL 的所有影像
P = spm_select(Inf, 'image', 'Select all your DARTEL input images');

% 2. 讀取影像標頭檔資訊
V = spm_vol(P);

% 3. 提取所有影像的維度並顯示
dims = cat(1, V.dim);
filenames = {V.fname}';

% 4. 找出與第一張影像維度不同的檔案
base_dim = dims(1,:);
bad_idx = find(any(dims ~= base_dim, 2));

if isempty(bad_idx)
    disp('所有影像維度都一致，請檢查是否是配對 (rc1/rc2) 的數量不對。');
else
    disp('找到維度不一致的檔案了！');
    for i = 1:length(bad_idx)
        fprintf('檔案: %s (維度: %d %d %d)\n', filenames{bad_idx(i)}, dims(bad_idx(i),:));
    end
end