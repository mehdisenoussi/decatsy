addpath('./decatsy_funs/');
subject_ind=3; sess=1;
indir='./decatsy_data/';
subj_behavdata_dir=[subj_dir 'log_files/'];
log_dir=sprintf('%ssubj%i/all_logs/s%ipart%i_txt/',subj_behavdata_dir,...
    subject_ind, subject_ind, sess);

s_ind_all='s_ind_all';
subjGroup_all='subjGroup_all';
session_all='session_all';
expPhase_all='expPhase_all';
condition_all='condition_all';
block_all='block_all';
triali_all='triali_all';
respTime_all='respTime_all';
respKey_all='respKey_all';
correctResp_all='correctResp_all';
correctSide_all='correctSide_all';
correctTilt_all='correctTilt_all';
precue_all='precue_all';
cue_all='cue_all';
validity_all='validity_all';
tiltsLvlV_all='tiltsLvlV_all';
tiltsLvlH_all='tiltsLvlH_all';
tiltStepsV_all='tiltStepsV_all';
tiltStepsH_all='tiltStepsH_all';
gratingOriL_all='gratingOriL_all';
gratingOriR_all='gratingOriR_all';

listing = dir([log_dir '*.txt']);
if isempty(listing)
    fprintf('NO FILES IN DIRECTORY'); return;
else
    for file_count=1:length(listing)
        [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
        respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
        tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
        textread([log_dir listing(file_count).name],...
        '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
        fprintf(['\n\nfile processed: ' listing(file_count).name '\n']);
        
        s_ind_all=[s_ind_all; s_ind(2:end)];
        subjGroup_all=[subjGroup_all; subjGroup(2:end)];
        session_all=[session_all; session(2:end)];
        expPhase_all=[expPhase_all; expPhase(2:end)];
        condition_all=[condition_all; condition(2:end)];
        block_all=[block_all; block(2:end)];
        triali_all=[triali_all; triali(2:end)];
        respTime_all=[respTime_all; respTime(2:end)];
        respKey_all=[respKey_all; respKey(2:end)];
        correctResp_all=[correctResp_all; correctResp(2:end)];
        correctSide_all=[correctSide_all; correctSide(2:end)];
        correctTilt_all=[correctTilt_all; correctTilt(2:end)];
        precue_all=[precue_all; precue(2:end)];
        cue_all=[cue_all; cue(2:end)];
        validity_all=[validity_all; validity(2:end)];
        tiltsLvlV_all=[tiltsLvlV_all; tiltsLvlV(2:end)];
        tiltsLvlH_all=[tiltsLvlH_all; tiltsLvlH(2:end)];
        tiltStepsV_all=[tiltStepsV_all; tiltStepsV(2:end)];
        tiltStepsH_all=[tiltStepsH_all; tiltStepsH(2:end)];
        gratingOriL_all=[gratingOriL_all; gratingOriL(2:end)];
        gratingOriR_all=[gratingOriR_all; gratingOriR(2:end)];
    end
end

all_alls= [s_ind_all subjGroup_all subjGroup_all expPhase_all condition_all block_all ...
triali_all respTime_all respKey_all correctResp_all correctSide_all ...
correctTilt_all precue_all cue_all validity_all tiltsLvlV_all tiltsLvlH_all ...
tiltStepsV_all tiltStepsH_all gratingOriL_all gratingOriR_all];


filename=[log_dir sprintf('subj%i_sess%i_all.txt',subject_ind,sess)];
fid=fopen(filename,'w');
for i=1:size(all_alls,1)
    fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
                all_alls{i,:});
end
fclose('all'); % close log file