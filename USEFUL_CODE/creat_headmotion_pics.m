clear; clc;

% ---------- root directory ----------
root_dir = '/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/';

% ---------- output directory ----------
out_dir = fullfile(root_dir, 'motion_plots_all_SES02');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

% ---------- task file patterns ----------
task_patterns = { 'rp_REST_%s.txt'};

task_labels = {'REST'};

% ---------- find subject folders ----------
d = dir(fullfile(root_dir, 'NTUSEC*'));
d = d([d.isdir]);

fprintf('Found %d subject folders.\n', numel(d));

for i = 1:numel(d)

    subj = d(i).name;   % e.g., s0008
    func_dir = fullfile(root_dir, subj, 'nii', 'ses02', 'REST_SES02');

    if ~exist(func_dir, 'dir')
        fprintf('[Skip] %s: no func folder\n', subj);
        continue;
    end

    fprintf('\nProcessing %s ...\n', subj);

    for t = 1:numel(task_patterns)

        rp_name = sprintf(task_patterns{t}, subj);
        rp_path = fullfile(func_dir, rp_name);
        fprintf('OK1');
        if ~exist(rp_path, 'file')
            fprintf('  [Missing] %s\n', rp_name);
            continue;
        end

        try
            rp = load(rp_path);
            fprintf('OK2 ');
            if size(rp, 2) < 6
                fprintf('  [Skip] %s: file does not have 6 columns\n', rp_name);
                continue;
            end


            % create invisible figure so batch processing is cleaner
            fig = figure('Visible', 'off', ...
                         'Color', 'w', ...
                         'Position', [100, 100, 1000, 700]);
            fprintf('OK3 ');
            % ---- translation ----
            subplot(2,1,1);
            plot(rp(:,1:3), 'LineWidth', 1.2);
            legend({'x','y','z'}, 'Location', 'best');
            title(sprintf('%s | %s | Translation (mm)', subj, task_labels{t}), ...
                  'Interpreter', 'none');
            xlabel('Volume');
            ylabel('mm');
            grid on;
            fprintf('OK4 ');
            % ---- rotation ----
            subplot(2,1,2);
            plot(rp(:,4:6), 'LineWidth', 1.2);
            legend({'pitch','roll','yaw'}, 'Location', 'best');
            title(sprintf('%s | %s | Rotation (radians)', subj, task_labels{t}), ...
                  'Interpreter', 'none');
            xlabel('Volume');
            ylabel('radians');
            grid on;
            fprintf('OK5 ');
            % ---- save ----
            out_png = fullfile(out_dir, sprintf('%s_%s_motion_plot.png', subj, task_labels{t}));
            out_fig = fullfile(out_dir, sprintf('%s_%s_motion_plot.fig', subj, task_labels{t}));
            fprintf('OK6 ');
            %exportgraphics(fig, out_png, 'Resolution', 300);
            savefig(fig, out_fig);
            fprintf('OK7 ');
            close(fig);

            fprintf('  [Saved] %s\n', out_png);

        catch ME
            fprintf('  [Error] %s\n', rp_name);
            fprintf('          %s\n', ME.message);
        end
    end
end

fprintf('\nDone. All plots saved to:\n%s\n', out_dir);