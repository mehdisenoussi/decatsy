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
subplot(2,3,2); hold on; blocks=sort(unique(block))';
for i=blocks
    y(:,i)=[dprime_valid dprime_invalid];
end
plot(blocks,y,.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
title('Validity effect');
ylabel('d-prime'); grid on;
if strcmp(experiment_phase,'train4') || strcmp(experiment_phase, 'main')
    bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
    set(gca,'XTick',[1 2]);
    set(gca,'XTickLabel',{'Valid' 'Invalid'});
end

% Plot the accuracy by validity (if in train4 or main)
subplot(2,3,3); hold on; y=zeros(2,length(blocks));
block_ind=1;
for b=blocks
    if validAndCorrectSide
        y(:,block_ind)=[mean(correctResp(logical(validity) & logical(correctSide) & b==block)) ...
            mean(correctResp(~logical(validity) & logical(correctSide) & (b==block)))]';
        
    else y(:,block_ind)=[mean(correctResp(logical(validity) & b==block)) ...
            mean(correctResp(~logical(validity) & b==block))];
    end
    block_ind=block_ind+1;
end
plot(1:length(blocks), y(1,:), 'color',[0 0 .8], 'marker', 'o');
plot(1:length(blocks),y(2,:), 'color',[.8 0 0], 'marker', 'o');
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
vertTargets=targetOri<45; %subplot(2,3,5);
y=zeros(2,length(blocks)); block_ind=1;
for b=blocks
    if validAndCorrectSide
        y(:,block_ind)=[mean(correctResp(logical(vertTargets) & logical(correctSide) & logical(validity) & b==block))...
            mean(correctResp(~logical(vertTargets) & logical(correctSide) & logical(validity) & b==block))]; hold on;
    else y(:,block_ind)=[mean(correctResp(logical(vertTargets) & b==block)) mean(correctResp(~logical(vertTargets) & b==block))]; hold on;
    end
    block_ind=block_ind+1;
end
plot(1:length(blocks), y(1,:), 'color',[0 0 .8], 'marker', 'o');
plot(1:length(blocks),y(2,:), 'color',[.8 0 0], 'marker', 'o');


bar(1,y(1),.5,'FaceColor',[0 0 .8]);%, 'FaceAlpha',.5);
bar(2,y(2),.5,'FaceColor',[.8 0 0]);%, 'FaceAlpha',.5);
title(sprintf('Orientation\ntilt levels: Vert=%.2f, Hori=%.2f',...
    tiltsLvlV(2), tiltsLvlH(2)));
ylabel('Propotion correct');
set(gca,'XTick',[1 2]);
set(gca,'XTickLabel',{'Vertical' 'Horizontal'});
ylim([.4 1]); grid on;



% Plot accuracy for each side
subplot(2,3,6);hold on;
y=zeros(2,length(blocks)); block_ind=1;
for b=blocks
    if validAndCorrectSide
        y(:,block_ind)=[mean(correctResp(logical(targetLoc(:,1) & logical(validity) & logical(correctSide) & b==block)))...
            mean(correctResp(logical(targetLoc(:,2) & logical(correctSide) & logical(validity) & b==block )))];
    else y(:,block_ind)=[mean(correctResp(logical(targetLoc(:,1) & b==block))) mean(correctResp(logical(targetLoc(:,2) & b==block)))]; 
    end
    block_ind=block_ind+1;
end
plot(1:length(blocks), y(1,:), 'color',[0 0 .8], 'marker', 'o');
plot(1:length(blocks),y(2,:), 'color',[.8 0 0], 'marker', 'o');

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

y2=[mean(correctResp(logical(tempLogical & targetLoc(:,1) & validity & targetOri>45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,1) & ~validity & targetOri>45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,2) & validity & targetOri>45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,2) & ~validity & targetOri>45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,1) & validity & targetOri<45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,1) & ~validity & targetOri<45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,2) & validity & targetOri<45)))...
    mean(correctResp(logical(tempLogical & targetLoc(:,2) & ~validity & targetOri<45)))];

ntpb=[sum(logical(tempLogical & targetLoc(:,1) & validity & targetOri>45))...
    sum(logical(tempLogical & targetLoc(:,1) & ~validity & targetOri>45))...
    sum(logical(tempLogical & targetLoc(:,2) & validity & targetOri>45))...
    sum(logical(tempLogical & targetLoc(:,2) & ~validity & targetOri>45))...
    sum(logical(tempLogical & targetLoc(:,1) & validity & targetOri<45))...
    sum(logical(tempLogical & targetLoc(:,1) & ~validity & targetOri<45))...
    sum(logical(tempLogical & targetLoc(:,2) & validity & targetOri<45))...
    sum(logical(tempLogical & targetLoc(:,2) & ~validity & targetOri<45))];

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
disp(mean(correctResp));