%% Cut the "end" of rp regressors (using beh CSV end_test_question_time)
%subname   = [8, 9, 11, 12, 19, 37, 49, 50, 128, 130, 136, 137, 138, 141, 142, 259, 260, 271, 272, 273, 274, 275, 276, 69, 71, 73, 79, 80, 81, 88, 184, 189, 190, 191, 192, 196, 197, 243, 254, 255, 256, 266, 270]; 
%pre_post  = 'post_test';
TR        = 2;         

data   = '/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses01/VRIT1/ars0008_TASK1_pas1.nii';
beh = '/bml/projects/07_inference-clinical-trial/projects/07-09_ntsec-lego-fmri-connectivity/data/derivatives/NTUSEC008/nii/ses01/VRIT1/rp_s0008_TASK1_pas1.txt';

subID = sprintf('s%04d', sub);


        behfile = fullfile(beh, subID, ...
                           [subID '_' run '_VRIT_onset_test.csv']);
        
        beh_tbl = readtable(behfile);
        
        
        last_test_end = max(beh_tbl{:, 'end_test_question_time'});
        
     
        true_length = fix(last_test_end / TR);
        
        
        regressorsfilename = fullfile(data, ...
            subID, 'func', ...
            ['rp_' subID '_TASK' rn '_' runname '.txt']);
        
        rp = load(regressorsfilename);
       
        true_length = min(true_length, size(rp, 1));
        
        rp_cut = rp(1:true_length, :);
 
        outdir = fullfile(data, subID, 'func');
        if ~exist(outdir, 'dir')
            mkdir(outdir);
        end
        
        outfile = fullfile(outdir, ...
            ['rp_cutend_' subID '_TASK' rn '_' runname '.txt']);
        
        save(outfile, 'rp_cut', '-ascii');
        
        fprintf('Sub %s run %s: original %d vols -> cut to %d vols\n', ...
            subID, run, size(rp,1), true_length);
