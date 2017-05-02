function []=decatsy_behavioral_simpleAnalysis(subject_ind, arg2, validAndCorrectSide)
    study_dir='./'; subject_ind=num2str(subject_ind);
    results_dir=[study_dir 'Results/subj' subject_ind '/'];
    if ~exist('validAndCorrectSide'); validAndCorrectSide=0; end
    if length(arg2)<=6
        experiment_phase=arg2;
        listing = dir([results_dir '*.txt']); file_found=0; file_count=1;
        if isempty(listing)
            fprintf('NO FILES IN DIRECTORY'); return;
        else
            while ~file_found
                [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
                respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
                tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
                textread([results_dir listing(file_count).name],...%'Subj-50-0170201T140609.txt'],...
                '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
                file_found=strcmp(experiment_phase, expPhase(2));
                
            end
        end
    end
end