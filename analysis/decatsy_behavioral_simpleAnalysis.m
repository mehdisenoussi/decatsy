%% Simple script for simple behavioral analysis and monitoring of observer's performances
% study_dir='/Users/mehdisenoussi/decatsy/';
% results_dir=[study_dir 'behav_data_and_scripts/Results/'];

% [s_ind, session, expPhase, condition, block, triali, respTime, respKey,...
%     correctResp, correctSide, correctTilt, cue, precue, validity,...
%     tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
%     textread([results_dir 'Subj-1-all.txt'],...
%     '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');

%study_dir='/Users/mehdisenoussi/Dropbox/postphd/decatsy/code/';

function []=decatsy_behavioral_simpleAnalysis(subject_ind, experiment_phase)
    study_dir='../'; subject_ind=num2str(subject_ind);
    results_dir=[study_dir 'Results/subj' subject_ind '/'];
    listing = dir([results_dir '*.txt']); file_found=0; file_count=1;
    if isempty(listing)
        fprintf('NO FILES IN DIRECTORY'); return;
    else
        while ~file_found
            [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
                respKey, correctResp, correctSide, correctTilt, cue, precue, validity,...
                tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
                textread([results_dir listing(file_count).name],...%'Subj-50-0170201T140609.txt'],...
                '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
            file_found=strcmp(experiment_phase, expPhase(2));
            if ~file_found && file_count<length(listing); file_count=file_count+1;
            else break; end
        end
    end
    processed_file=listing(file_count).name;

    correctResp=str2double(correctResp(2:end)); cue=str2double(cue(2:end));
    precue=str2double(precue(2:end)); respTime=str2double(respTime(2:end));
    gratingOriR=str2double(gratingOriR(2:end)); validity=str2double(validity(2:end));
    correctSide=str2double(correctSide(2:end)); correctTilt=str2double(correctTilt(2:end));
    tiltsLvlV=str2double(tiltsLvlV(2:end)); tiltsLvlH=str2double(tiltsLvlH(2:end));
    triali=str2double(triali(2:end)); respKey=respKey(2:end);
    gratingOriL=str2double(gratingOriL(2:end));

    rej_behav_trials=~logical(validity==-5); n_trials=sum(rej_behav_trials);

    correctResp=correctResp(rej_behav_trials); cue=cue(rej_behav_trials);
    precue=precue(rej_behav_trials); respTime=respTime(rej_behav_trials);
    gratingOriR=gratingOriR(rej_behav_trials); validity=validity(rej_behav_trials);
    correctSide=correctSide(rej_behav_trials); correctTilt=correctTilt(rej_behav_trials);
    tiltsLvlH=tiltsLvlH(rej_behav_trials); tiltsLvlV=tiltsLvlV(rej_behav_trials);
    triali=triali(rej_behav_trials); respKey=respKey(rej_behav_trials);
    gratingOriL=gratingOriL(rej_behav_trials);

    hits=zeros(2,n_trials); falsealarms=zeros(2,n_trials);
    n_sig=[0 0]; n_nsig=[0 0];
    misses=zeros(1,n_trials);correctrej=zeros(1,n_trials);
    if ~strcmp(expPhase(2), 'train1')
        leftResps=[{'s'} {'d'}]; rightResps=[{'k'} {'l'}];
        valid_trials_ind=find(validity==1); invalid_trials=find(validity==0);
        trialsbyvalidity={valid_trials_ind invalid_trials};
        for valid_ind=1:2
            for i=trialsbyvalidity{valid_ind}'
                if ~correctSide(i); misses(i)=1;
                else
                    side=logical([sum(strcmp(respKey(i), leftResps)) sum(strcmp(respKey(i), rightResps))]);
                    gratOris=[gratingOriL(i) gratingOriR(i)]; gratOriTarget=gratOris(side);
                    % counter-clockwise response ? (can be changed to clockwise by
                    % switching the indices to 2s instead of 1s for the left- and
                    % rightResps variables
                    ccwResp=(strcmp(respKey(i), leftResps(1)) || strcmp(respKey(i), rightResps(1)));
                    if gratOriTarget<0 || (gratOriTarget>45 && gratOriTarget<90)
                        n_sig(valid_ind)=n_sig(valid_ind)+1;
                        if ccwResp; hits(valid_ind, i)=1; end
                    else
                        n_nsig(valid_ind)=n_nsig(valid_ind)+1;
                        if ccwResp; falsealarms(valid_ind, i)=1; end
                    end
                end
            end
        end
    end


    if (sum(hits(1,:))/n_sig(1))~=0 && ((sum(hits(1,:))/n_sig(1)))~=1
        valhits=sum(hits(1,:))/n_sig(1);
    else valhits=(sum(hits(1,:))+1)/n_sig(1); end

    if (sum(hits(2,:))/n_sig(2))~=0 && (sum(hits(2,:))/n_sig(2))~=1
        invalhits=sum(hits(2,:))/n_sig(2);
    else invalhits=(sum(hits(2,:))+1)/n_sig(2); end

    if ((sum(falsealarms(1,:))/n_nsig(1)))~=0 && ((sum(falsealarms(1,:))/n_nsig(1)))~=1
        valfas=sum(falsealarms(1,:))/n_nsig(1);
    else valfas=(sum(falsealarms(1,:))+1)/n_nsig(1); end

    if (sum(falsealarms(2,:))/n_nsig(2))~=0 && (sum(falsealarms(2,:))/n_nsig(2))~=1
        invalfas=sum(falsealarms(2,:))/n_nsig(2);
    else invalfas=(sum(falsealarms(2,:))+1)/n_nsig(2); end


    dprime_valid=norminv(valhits)-norminv(valfas);
    dprime_invalid=norminv(invalhits)-norminv(invalfas);

    %% Plots

    switch experiment_phase
        case {'train1', 'train2', 'train4', 'main'}
            % Plot the distribution of reaction times
            figure();
            subplot(2,1,1); hold on;
            h1=histogram(respTime(logical(cue)), 5, 'Normalization', 'probability','FaceColor',[0 0 .8]);
            h2=histogram(respTime(~logical(cue)), 5, 'Normalization', 'probability','FaceColor',[.8 0 0]);
            xlim([-.05 .85]); xlabel('Reaction times (ms)'); ylabel('Probability');
            switch char(expPhase(2))
                case {'train1', 'train2', 'train3'}
                    title(['Histogram of reaction times for phase' expPhase(2)]);
                case {'train4', 'main'}
                    title(sprintf(['Histogram of reaction times in valid and '...
                        'invalid conditions for phase %s'], expPhase{2}));
            end

            % Plot the d-prime of each condition
            subplot(2,1,2); y=[dprime_valid dprime_invalid]; hold on;
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);
            bar(2,y(2),.5,'FaceColor',[.8 0 0]);
            title('d-prime valid and invalid condition (blue=valid)');
            set(gca,'XTick',[1 2]);
            set(gca,'XTickLabel',{'Valid' 'Invalid'});

        case 'train3'
            figure(); hold on;
            plot(1:sum(rej_behav_trials), tiltsLvlV, 'color',[0 .8 0], 'LineWidth',2);
            plot(1:sum(rej_behav_trials), tiltsLvlH, 'color',[.8 0 .8], 'LineWidth',2);
            ylabel('Tilt levels (?)'); xlabel('Trial number'); grid;
            legend('Vertical grating','Horizontal grating');
            xlim([-1 sum(rej_behav_trials)+1]);

    end
end


