%% Simple script for simple behavioral analysis and monitoring of observer's performances

function []=decatsy_behavioral_simpleAnalysis(subject_ind, arg2,...
    validAndCorrectSide, study_dir)
    addpath('./decatsy_funs/');
    if ~exist('study_dir'); study_dir='./'; end
    subject_ind=num2str(subject_ind);
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
                if ~file_found && file_count<length(listing); file_count=file_count+1;
                else break; end
            end
            processed_file=listing(file_count).name;
        end
    else
        processed_file=arg2;
        [s_ind, subjGroup, session, expPhase, condition, block, triali, respTime,...
        respKey, correctResp, correctSide, correctTilt, precue, cue, validity,...
        tiltsLvlV, tiltsLvlH, tiltStepsV, tiltStepsH, gratingOriL, gratingOriR] = ...
        textread([results_dir processed_file],...
        '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s');
        experiment_phase=char(expPhase(2));
    end
    fprintf(['\n\nfile processed: ' processed_file '\n\n']);

    correctResp=str2double(correctResp(2:end)); cue=str2double(cue(2:end));
    precue=str2double(precue(2:end)); respTime=str2double(respTime(2:end));
    gratingOriR=str2double(gratingOriR(2:end)); validity=str2double(validity(2:end));
    correctSide=str2double(correctSide(2:end)); correctTilt=str2double(correctTilt(2:end));
    tiltsLvlV=str2double(tiltsLvlV(2:end)); tiltsLvlH=str2double(tiltsLvlH(2:end));
    triali=str2double(triali(2:end)); respKey=respKey(2:end); session=str2double(session(2));
    gratingOriL=str2double(gratingOriL(2:end)); subjGroup=str2double(subjGroup(2));

    rej_behav_trials=~logical(validity==-5); n_trials=sum(rej_behav_trials);

    correctResp=correctResp(rej_behav_trials); cue=cue(rej_behav_trials);
    precue=precue(rej_behav_trials); respTime=respTime(rej_behav_trials);
    gratingOriR=gratingOriR(rej_behav_trials); validity=validity(rej_behav_trials);
    correctSide=correctSide(rej_behav_trials); correctTilt=correctTilt(rej_behav_trials);
    tiltsLvlH=tiltsLvlH(rej_behav_trials); tiltsLvlV=tiltsLvlV(rej_behav_trials);
    triali=triali(rej_behav_trials); respKey=respKey(rej_behav_trials);
    gratingOriL=gratingOriL(rej_behav_trials);
    
    emp_valid=precue==cue; validity=emp_valid;
    feature_disp=gratingOriR<45; % 0=horiz-left/verti-right, 1=the inverse
    
    [condition, cueStimAsso, leftResps, rightResps, ~, validRatio, ~]=...
    init_cueStimAsso_keys_stimParams(subjGroup, session, experiment_phase);
    
    switch condition
        case 'feature'
            targetFeat=cueStimAsso(logical(cue)+1);
            targetRightVert=strcmp(targetFeat, 'vert') & feature_disp;
            targetLeftHori=strcmp(targetFeat, 'hori') & ~feature_disp;
            targetRight=targetRightVert + targetLeftHori;
            targetLoc=[~targetRight targetRight];
        case 'spatial'
            targetPos=cueStimAsso(logical(cue)+1);
            if strcmp(targetPos,'left');
                targetFeat=stimFeat(logical(trials.feature(1,triali))+1);
            else targetFeat=stimFeat(logical(trials.feature(2,triali))+1);
            end
    end
    
    hits=zeros(2,n_trials); falsealarms=zeros(2,n_trials); n_sig=[0 0];...
    n_nsig=[0 0]; gratOriTarget=zeros(1,n_trials); misses=zeros(1,n_trials);
    if ~strcmp(expPhase(2), 'train1')
        valid_trials_ind=find(validity==1); invalid_trials=find(validity==0);
        trialsbyvalidity={valid_trials_ind invalid_trials};
        for valid_ind=1:2
            for i=trialsbyvalidity{valid_ind}'
                if ~correctSide(i); misses(i)=1;
                else
                    gratOris=[gratingOriL(i) gratingOriR(i)]; gratOriTarget(i)=gratOris(logical(targetLoc(i,:)));
                    % counter-clockwise response ? (can be changed to clockwise by
                    % switching the indices to 2s instead of 1s for the left- and
                    % rightResps variables
                    ccwResp=(strcmp(respKey(i), leftResps(1)) || strcmp(respKey(i), rightResps(1)));
                    if gratOriTarget(i)<0 || (gratOriTarget(i)>45 && gratOriTarget(i)<90)
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
    elseif (sum(hits(1,:))/n_sig(1))==0
        valhits=(sum(hits(1,:))+1)/n_sig(1);
    elseif ((sum(hits(1,:))/n_sig(1)))==1
        valhits=(sum(hits(1,:))-1)/n_sig(1);
    end

    if (sum(hits(2,:))/n_sig(2))~=0 && (sum(hits(2,:))/n_sig(2))~=1
        invalhits=sum(hits(2,:))/n_sig(2);
    elseif (sum(hits(2,:))/n_sig(2))==0
        invalhits=(sum(hits(2,:))+1)/n_sig(2);
    elseif (sum(hits(2,:))/n_sig(2))==1
        invalhits=(sum(hits(2,:))-1)/n_sig(2); 
    end

    if ((sum(falsealarms(1,:))/n_nsig(1)))~=0 && ((sum(falsealarms(1,:))/n_nsig(1)))~=1
        valfas=sum(falsealarms(1,:))/n_nsig(1);
    elseif ((sum(falsealarms(1,:))/n_nsig(1)))==0
        valfas=(sum(falsealarms(1,:))+1)/n_nsig(1);
    elseif ((sum(falsealarms(1,:))/n_nsig(1)))==1
        valfas=(sum(falsealarms(1,:))-1)/n_nsig(1);
    end

    if (sum(falsealarms(2,:))/n_nsig(2))~=0 && (sum(falsealarms(2,:))/n_nsig(2))~=1
        invalfas=sum(falsealarms(2,:))/n_nsig(2);
    elseif (sum(falsealarms(2,:))/n_nsig(2))==0
        invalfas=(sum(falsealarms(2,:))+1)/n_nsig(2);
    elseif (sum(falsealarms(2,:))/n_nsig(2))==1
        invalfas=(sum(falsealarms(2,:))-1)/n_nsig(2);
    end

    dprime_valid=norminv(valhits)-norminv(valfas);
    dprime_invalid=norminv(invalhits)-norminv(invalfas);
    
    %% Plots
    
    switch experiment_phase
        case {'train1', 'train2', 'train4', 'main'}
            
            % Plot the distribution of reaction times
            figure();
            subplot(2,3,1); hold on;
            % suptitle(sprintf('Data for subject %s - phase %s', subject_ind, expPhase{2}));
            h1=histogram(respTime(logical(validity)), 5, 'Normalization', 'probability','FaceColor',[0 0 .8]);
            h2=histogram(respTime(~logical(validity)), 5, 'Normalization', 'probability','FaceColor',[.8 0 0]);
            plot([median(respTime(logical(validity))) median(respTime(logical(validity)))],...
                [0 max([h1.Values h2.Values]*1.2)], 'color',[0 0 .8])
            plot([median(respTime(~logical(validity))) median(respTime(~logical(validity)))],...
                [0 max([h1.Values h2.Values]*1.2)], 'color',[.8 0 0])
            xlim([-.05 1.05]); xlabel('Reaction times (ms)'); ylabel('Probability');
            grid on;
            switch char(expPhase(2))
                case {'train1', 'train2', 'train3'}
                    title(['Histogram of reaction times']);
                case {'train4', 'main'}
                    title(sprintf('Histogram of reaction times\nvalid versus invalid condition'));
                    legend('valid','invalid','Location','NorthWest')
            end
            

            % Plot the d-prime of each condition (if in train4 or main)
            subplot(2,3,2); y=[dprime_valid dprime_invalid]; hold on;
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
            title('Validity effect');
            ylabel('d-prime'); grid on;
            if strcmp(experiment_phase,'train4') || strcmp(experiment_phase, 'main')
                bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
                set(gca,'XTick',[1 2]);
                set(gca,'XTickLabel',{'Valid' 'Invalid'});
            end
            
            % Plot the accuracy by validity (if in train4 or main)
            subplot(2,3,3);
            if validAndCorrectSide
                y=[mean(correctResp(logical(validity) & logical(correctSide)))...
                    mean(correctResp(~logical(validity) & logical(correctSide)))]; hold on;
            else y=[mean(correctResp(logical(validity))) mean(correctResp(~logical(validity)))]; hold on;
            end
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
            title('Validity effect');
            ylabel('Propotion correct');
            ylim([.4 1]); grid on;
            if strcmp(experiment_phase,'train4') || strcmp(experiment_phase, 'main')
                bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
                set(gca,'XTick',[1 2]);
                set(gca,'XTickLabel',{'Valid' 'Invalid'});
            end
            
            % Plot accuracy for each cue
            subplot(2,3,4);
            if validAndCorrectSide
                y=[mean(correctResp(logical(cue) & logical(correctSide) & logical(validity)))...
                    mean(correctResp(~logical(cue) & logical(correctSide) & logical(validity)))]; hold on;
            else y=[mean(correctResp(logical(cue))) mean(correctResp(~logical(cue)))]; hold on;
            end
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
            title('Cue');
            ylabel('Propotion correct');
            bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
            set(gca,'XTick',[1 2]);
            set(gca,'XTickLabel',{'Square' 'Diamond'});
            ylim([.4 1]); grid on;
            
            % Plot accuracy for each orientation
            vertTargets=gratOriTarget<45;
            subplot(2,3,5);
            if validAndCorrectSide
                y=[mean(correctResp(logical(vertTargets) & logical(correctSide)' & logical(validity)'))...
                    mean(correctResp(~logical(vertTargets) & logical(correctSide)' & logical(validity)'))]; hold on;
            else y=[mean(correctResp(logical(vertTargets))) mean(correctResp(~logical(vertTargets)))]; hold on;
            end
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
            bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
            title(sprintf('Orientation\ntilt levels: Vert=%.2f, Hori=%.2f',...
                tiltsLvlV(2), tiltsLvlH(2)));
            ylabel('Propotion correct');
            set(gca,'XTick',[1 2]);
            set(gca,'XTickLabel',{'Vertical' 'Horizontal'});
            ylim([.4 1]); grid on;
            
            % Plot accuracy for each side
            subplot(2,3,6);
            if validAndCorrectSide
                y=[mean(correctResp(logical(targetLoc(:,1) & logical(validity) & logical(correctSide))))...
                    mean(correctResp(logical(targetLoc(:,2) & logical(correctSide) & logical(validity))))]; hold on;
            else y=[mean(correctResp(logical(targetLoc(:,1)))) mean(correctResp(logical(targetLoc(:,2))))]; hold on;
            end
            bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
            bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
            title('Location');
            ylabel('Propotion correct');
            set(gca,'XTick',[1 2]);
            set(gca,'XTickLabel',{'Left Target' 'Right Target'});
            ylim([.4 1]); grid on;
            
            
            if validAndCorrectSide; tempLogical=correctSide;
            else tempLogical=ones(size(correctSide)); end
            y1=[mean(correctResp(logical(tempLogical & targetLoc(:,1) & validity)))...
                mean(correctResp(logical(tempLogical & targetLoc(:,1) & ~validity)))...
                 mean(correctResp(logical(tempLogical & targetLoc(:,2) & validity)))...
                 mean(correctResp(logical(tempLogical & targetLoc(:,2) & ~validity)))];

            y2=[mean(correctResp(logical(tempLogical & targetLoc(:,1) & validity & strcmp(targetFeat,'hori'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,1) & ~validity & strcmp(targetFeat,'hori'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,2) & validity & strcmp(targetFeat,'hori'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,2) & ~validity & strcmp(targetFeat,'hori'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,1) & validity & strcmp(targetFeat,'vert'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,1) & ~validity & strcmp(targetFeat,'vert'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,2) & validity & strcmp(targetFeat,'vert'))))...
                mean(correctResp(logical(tempLogical & targetLoc(:,2) & ~validity & strcmp(targetFeat,'vert'))))];

            ntpb=[sum(logical(tempLogical & targetLoc(:,1) & validity & strcmp(targetFeat,'hori')))...
                sum(logical(tempLogical & targetLoc(:,1) & ~validity & strcmp(targetFeat,'hori')))...
                sum(logical(tempLogical & targetLoc(:,2) & validity & strcmp(targetFeat,'hori')))...
                sum(logical(tempLogical & targetLoc(:,2) & ~validity & strcmp(targetFeat,'hori')))...
                sum(logical(tempLogical & targetLoc(:,1) & validity & strcmp(targetFeat,'vert')))...
                sum(logical(tempLogical & targetLoc(:,1) & ~validity & strcmp(targetFeat,'vert')))...
                sum(logical(tempLogical & targetLoc(:,2) & validity & strcmp(targetFeat,'vert')))...
                sum(logical(tempLogical & targetLoc(:,2) & ~validity & strcmp(targetFeat,'vert')))];
            
            %disp(sprintf('Number of trials per bar in left plot %i %i %i %i %i %i %i %i', ntpb));
            
            figure();
            subplot(1,2,1); hold on;
            bar(1,y1(1),.5,'FaceColor',[0 0 0]);%, 'FaceAlpha',.5);
            bar(1.5,y1(2),.5,'FaceColor',[.5 .5 .5]);%, 'FaceAlpha',.5);
            bar(2.5,y1(3),.5,'FaceColor',[0 0 0]);%, 'FaceAlpha',.5);
            bar(3,y1(4),.5,'FaceColor',[.5 .5 .5]);%, 'FaceAlpha',.5);
            title('Accuracy by Validity and target Location'); ylabel('Propotion correct'); set(gca,'XTick',[1 1.5 2.5 3]);
            set(gca,'XTickLabel',{'Left Valid' 'Left Invalid' 'Right Valid' 'Right Invalid' });
            ylim([.4 1]); grid on;
            
            subplot(1,2,2); hold on;
            bar([1 1.5 2.5 3 4 4.5 5.5 6], y2', 1);
            title(sprintf(['Accuracy by Side, target Orientation and target Location\n'...
                 'Number of trials: top of each bar']));
            ylabel('Propotion correct'); ylim([.4 1]); grid on;
            set(gca,'XTick',[1 1.5 2.5 3 4 4.5 5.5 6]); set(gca,'XTickLabel','');
            xlabetxt = {'Hori Valid Left' 'Hori Invalid Left'...
                'Hori Valid Right' 'Hori Invalid Right' 'Vert Valid Left'...
                'Vert Invalid Left' 'Vert Valid Right' 'Vert Invalid Left'};
            ypos = min(ylim)*.99;
            text([1 1.5 2.5 3 4 4.5 5.5 6],repmat(ypos,8,1), ...
                 xlabetxt','horizontalalignment','right','Rotation',45,'FontSize',10)
            text(.55,77.5,'A','FontSize',10)
            
            %bar(y,'group')
            xt=[1 1.5 2.5 3 4 4.5 5.5 6]-0.2;
            yt=y2*1.01;
            for foo=1:8
                ytxt=num2str(ntpb(foo),'%i');
                text(xt(foo),yt(foo),ytxt,'fontsize',10,'fontweight','bold')
            end
            

        case 'train3'
            figure(); hold on;
            plot(1:sum(rej_behav_trials), tiltsLvlV, 'color',[0 .8 0], 'LineWidth',2);
            plot(1:sum(rej_behav_trials), tiltsLvlH, 'color',[.8 .5 0], 'LineWidth',2);
            ylabel('Tilt levels (in degrees of visual angle)'); xlabel('Trial number');
            legend('Vertical grating','Horizontal grating');
            xlim([-1 sum(rej_behav_trials)+1]); grid on;
            tiltLvls=[mean(tiltsLvlV(end-10:end,:),1) mean(tiltsLvlH(end-10:end,:),1)];
            title(sprintf('Final tilt levels:\nVert=%.2f, Hori=%.2f',...
                tiltLvls));
            disp('aa');
            

    end
end


