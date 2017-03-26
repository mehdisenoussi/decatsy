% arg2='/Users/mehdisenoussi/decatsy/eeg_data/Results/subj3/Subj-3-20170216_allblocks_fixbreakfix.txt';
% arg2='/Users/mehdisenoussi/decatsy/eeg_data/Results/subj3/Subj-3-20170216_allblocks.txt';


aa=char(TMPEEG.event.type);
% now launch "eeglab" by the command line to get the biosig toolbox's
% str2double
bb=str2double(aa(:,3:4));
trialnum=zeros(size(bb,1),1); trialn=0;
for ind=1:size(bb,1)
    if bb(ind)==10; trialn=trialn+1; end
    trialnum(ind)=trialn;
    if bb(ind)==99; fixbreaktrialn(trialn)=1; end
end

logfixbreak=strcmp(respTime(2:end),'fixBreak');
%fixbreaktrialn(end:length(logfixbreak))=0;
eegfixbreak=fixbreaktrialn;

figure; hold on
plot(logfixbreak+.1,'.-', 'color', [0 0 1 .5])
plot(eegfixbreak,'.-', 'color', [1 0 0 .5])
legend([{'log'};{'eeg triggers'}]);

%%
% %subj3-sess2
% logfixbreak2=[logfixbreak(1:147); 1; 1; logfixbreak(148:end)];
% logfixbreak2=logfixbreak;

%subj3-sess1
% logfixbreak2=[logfixbreak(1:64); 1; 0; logfixbreak(65:end)];
figure; plot(logfixbreak==eegfixbreak', 'g.-')
 

%%
for i=2:size(triali)
    if triali(i)~=(triali(i-1)+1)
        fprintf(sprintf('trial-i=%i\ttrial-i+1=%i\n',(triali(i-1)+1), triali(i)))
    end
end







mankepttrials=ones(1,size(validity,1)); mankepttrials(rejtrials_man)=0;
validity2=validity(logical(mankepttrials));

figure(); hold on; elec=53;
plot(timeps, mean(epochEEGclean.data(elec, :, logical(validity2)),3),...
    'color',[0 0 1 .5], 'linewidth', 2);
plot(timeps, mean(epochEEGclean.data(elec, :, ~logical(validity2)),3),...
    'color',[1 0 0 .5], 'linewidth', 2)
legend([{'CPz valid'}, {'CPz invalid'}]);


figure(); hold on
plot(timeps, mean(epochEEGclean.data(47, :, logical(validity2) & logical(cue2==45)),3),...
    'color',[0 0 1 .5], 'linewidth', 2)
plot(timeps, mean(epochEEGclean.data(47, :, logical(validity2) & logical(cue2==0)),3),...
    'color',[0 0 .5 .5], 'linewidth', 2)
plot(timeps, mean(epochEEGclean.data(49, :, logical(validity2) & logical(cue2==45)),3),...
    'color',[0 1 0 .5], 'linewidth', 2)
plot(timeps, mean(epochEEGclean.data(49, :, logical(validity2) & logical(cue2==0)),3),....
    'color',[0 .5 0 .5], 'linewidth', 2)
legend([{'PO3 - 45'}, {'PO3 - 0'}, {'PO4 - 45'}, {'PO4 - 0'}]);
plot(timeps, mean(epochEEGclean.data(53, :, ~logical(validity2)),3),'color',[1 0 0 .5])

set(gca,'XTickLabel', [timeps(1:696) timeps(697:end)-2120])
% pre-trial: -600:0 = 1:154
% precue+ISI1: 0:2120 = 155:696
% Stim+ISI2: 0:3070 = 697:940



%% check trigger latency

aa=char(TMPEEG.event.type);
% now launch "eeglab" by the command line to get the biosig toolbox's
% str2double
bb=str2double(aa(:,3:4));
trialnum=zeros(size(bb,1),1); trialn=0;
for ind=1:size(bb,1)
    if bb(ind)==10; trialn=trialn+1; end
    trialnum(ind)=trialn;
    if bb(ind)==99; fixbreaktrialn(trialn)=1; end
end

a=struct2table(TMPEEG.event);
lats=table2array(a(:,1));
events=str2double(aa(:,3:4));

% take trial start as reference
bloups=zeros(8,trialn); bloups=bloups-1;
for i=1:length(trialnum)
    if sum(events(i)==[10 20 30 40 50 60 70 80])
        if events(i)==10; last_trial_start=lats(i); end
        bloups(events(i)/10,trialnum(i))=(lats(i)-last_trial_start)*(1./TMPEEG.srate);
    end
end

% % take precue as reference
% bloups=zeros(8,trialn); bloups=bloups-1;
% for i=1:length(trialnum)
%     if sum(events(i)==[10 20 30 40 50 60 70 80])
%         if events(i)==20; last_precue=lats(i); end
%         bloups(events(i)/10,trialnum(i))=(lats(i)-last_precue)*(1./TMPEEG.srate);
%     end
% end

lats_byev={};
for i=2:8
    bmask=bloups(i,:)>=0;
    lats_byev{i}=[bloups(i,logical(squeeze(bmask)))];
end

figure; hold on;
for i=2:8
    plot(ones(length(lats_byev{i}),1)+i-1,lats_byev{i} ,'o')
end
title(sprintf('events latencies relative to precue start (event 20)\n(x axis * trigger, e.g. 2=20=precue)'))
grid;

ev_titles={'precue','ISI1 start','cue + Stim pres','ISI2 start','respond period','response','ITI'};
figure()
for i=2:8
    subplot(4,2,i-1)
    uniqs=unique(lats_byev{i})-.0005; uniqs=[uniqs uniqs(end)+.001];
    mmlats=minmax(lats_byev{i}); bins=mmlats(1):.001:mmlats(2);
    hist(lats_byev{i},bins)
    title(ev_titles{i-1})
end








