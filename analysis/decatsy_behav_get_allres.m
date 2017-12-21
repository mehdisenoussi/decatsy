function [alldat]=decatsy_behav_get_alldat(s_num, sess, arg)
    %addpath('./decatsy_funs/');
    subj_dir=sprintf('./decatsy_data/subj%i/log_files/',s_num);
    sess_dir=[subj_dir sprintf('sess%i/',sess)];
    
    if ~exist('validAndCorrectSide'); validAndCorrectSide=1; end
    if ~exist('arg'); arg=''; end
    
    % is it the concatenation of all log files from an eeg session ?
    allblocksEEGsess=0;
    if isempty(arg)
        processed_file=[subj_dir sprintf('subj%i_sess%i_all.txt',s_num,sess)];
        [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
        respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
        tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
        textread(processed_file,...
        '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
        experiment_phase=char(expPhase(2));
        allblocksEEGsess=1;
        
    elseif length(arg)<=6
        experiment_phase=arg;
        listing = dir([sess_dir 'train/' '*.txt']); file_found=0; file_count=1;
        if isempty(listing)
            fprintf('NO FILES IN DIRECTORY'); return;
        else
            while ~file_found
                [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
                respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
                tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
                textread([results_dir listing(file_count).name],...
                '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
                file_found=strcmp(experiment_phase, expPhase(2));
                if ~file_found && file_count<length(listing); file_count=file_count+1;
                else break; end
            end
            processed_file=listing(file_count).name;
        end
    elseif length(arg)>6
        processed_file=arg;
        [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
        respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
        tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
        textread(processed_file,...
        '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
        experiment_phase=char(expPhase(2));
    end
    %fprintf(['\n\nfile processed: ' processed_file '\n\n']);

    correctResp=str2double(correctResp(2:end)); cue=str2double(cue(2:end));
    precue=str2double(precue(2:end)); respTime=str2double(respTime(2:end));
    gratingOriR=str2double(gratingOriR(2:end)); validity=str2double(validity(2:end));
    correctSide=str2double(correctSide(2:end)); correctTilt=str2double(correctTilt(2:end));
    tiltsLvlV=str2double(tiltsLvlV(2:end)); tiltsLvlH=str2double(tiltsLvlH(2:end));
    triali=str2double(triali(2:end)); respKey=respKey(2:end); session=str2double(session(2));
    gratingOriL=str2double(gratingOriL(2:end)); subjGroup=str2double(subjGroup(2));
    block=str2double(block(2:end));

    rej_behav_trials=~logical(validity==-5); n_trials=sum(rej_behav_trials);
    % save rejected trials for the EEG preproc IF this files contains ALL
    % logs of an EEG session
    if allblocksEEGsess % && ~exist(torejtrialsbehav_file)
        indir='./decatsy_data/';
        subj_dir=[indir sprintf('subj%i/',s_num)];
        subj_eeg_dir=[subj_dir 'eeg_files/'];
        save(sprintf('./decatsy_data/subj%i/log_files/subj%i_sess%i_behav_trials_to_rej.mat',...
            s_num,s_num,session), 'rej_behav_trials');
    end

    correctResp=correctResp(rej_behav_trials); cue=cue(rej_behav_trials);
    precue=precue(rej_behav_trials); respTime=respTime(rej_behav_trials);
    gratingOriR=gratingOriR(rej_behav_trials); validity=validity(rej_behav_trials);
    correctSide=correctSide(rej_behav_trials); correctTilt=correctTilt(rej_behav_trials);
    tiltsLvlH=tiltsLvlH(rej_behav_trials); tiltsLvlV=tiltsLvlV(rej_behav_trials);
    triali=triali(rej_behav_trials); respKey=respKey(rej_behav_trials);
    gratingOriL=gratingOriL(rej_behav_trials); block=block(rej_behav_trials);
    
    emp_valid=precue==cue; validity=emp_valid;
    feature_disp=gratingOriR<45; % 0=horiz-left/verti-right, 1=the inverse
    
    [condition, cueStimAsso, leftResps, rightResps, ~, validRatio, ~]=...
    init_cueStimAsso_keys_stimParams(subjGroup, sess, experiment_phase);
    
    gratingOris=[gratingOriL gratingOriR];
    switch condition
        case 'feature'
            targetFeat=cueStimAsso(logical(cue)+1);
            targetRightVert=strcmp(targetFeat, 'vert') & feature_disp;
            targetLeftHori=strcmp(targetFeat, 'hori') & ~feature_disp;
            targetRight=targetRightVert + targetLeftHori;
            targetLoc=[~targetRight targetRight];
            targetOri=gratingOris(logical(targetLoc));
        case 'spatial'
            targetRight=strcmp(cueStimAsso(logical(cue)+1),'right');
            targetLoc=[~targetRight targetRight];
            targetOri=gratingOris(targetLoc);
    end
    
    hitsall=zeros(2,n_trials); fasall=zeros(2,n_trials); n_sig=[0 0];...
    n_nsig=[0 0]; gratOriTarget=zeros(1,n_trials); misses=zeros(1,n_trials);
    sig=zeros(1,n_trials); nsig=zeros(1,n_trials);
    if ~strcmp(expPhase(2), 'train1')
        valid_trials_ind=find(validity==1); invalid_trials=find(validity==0);
        trialsbyvalidity={valid_trials_ind invalid_trials};
        for valid_ind=1:2
            for i=trialsbyvalidity{valid_ind}'
                if ~correctSide(i); misses(i)=1;
                else
                    gratOris=[gratingOriL(i) gratingOriR(i)];
                    gratOriTarget(i)=gratOris(logical(targetLoc(i,:)));
                    % counter-clockwise response ? (can be changed to clockwise by
                    % switching the indices to 2s instead of 1s for the left- and
                    % rightResps variables
                    ccwResp=(strcmp(respKey(i), leftResps(1)) || strcmp(respKey(i), rightResps(1)));
                    if gratOriTarget(i)<0 || (gratOriTarget(i)>45 && gratOriTarget(i)<90)
                        n_sig(valid_ind)=n_sig(valid_ind)+1;
                        sig(i)=1;
                        if ccwResp; hitsall(valid_ind, i)=1; end
                    else
                        n_nsig(valid_ind)=n_nsig(valid_ind)+1;
                        nsig(i)=1;
                        if ccwResp; fasall(valid_ind, i)=1; end
                    end
                end
            end
        end
    end
    
    alldat.s_num=s_num; alldat.sess=sess; alldat.correctResp=correctResp;
    alldat.cue=cue; alldat.validity=validity; alldat.precue=precue;
    alldat.respTime=respTime; alldat.gratingOriR=gratingOriR;
    alldat.correctSide=correctSide; alldat.correctTilt=correctTilt;
    alldat.tiltsLvlV=tiltsLvlV; alldat.tiltsLvlH=tiltsLvlH;
    alldat.triali=triali; alldat.respKey=respKey; alldat.session=session;
    alldat.gratingOriL=gratingOriL; alldat.subjGroup=subjGroup;
    alldat.block=block; alldat.hitsall=hitsall'; alldat.fasall=fasall';
    alldat.n_sig=n_sig; alldat.n_nsig=n_nsig; alldat.condition=condition;
    alldat.sig=sig; alldat.nsig=nsig;
end