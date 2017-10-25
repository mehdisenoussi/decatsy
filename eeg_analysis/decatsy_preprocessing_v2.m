%% 
addpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/')
chanfile='63ElecsDescartes.elp';
eeglab; close;

%% Read EEG data in dir
s_ind=5; session=1;

% this needs to be fixed so that the file architecture on my laptop is the
% same as the one we decided and described in decatsy_file_architecture
indir='./decatsy_data/';
subj_dir=[indir sprintf('subj%i/',s_ind)];
subj_eeg_dir=[subj_dir 'eeg_files/'];
TMPEEG = pop_loadset('filename',sprintf('subj%i_sess%i.set',s_ind,session),...
    'filepath', subj_eeg_dir);

%% Electrode Replace
rplc=0; channel2rplc = [];
if rplc; TMPEEG = pop_interp(TMPEEG, channel2rplc, 'spherical'); end

%% Remove baseline and filter
TMPEEG = pop_rmbase(TMPEEG, [], 1:size(TMPEEG.data,2));
% Remove electrical line noise
TMPEEG=pop_eegfiltnew(TMPEEG,48,52,[],1);
% remove very slow drifts
% TMPEEG=pop_eegfiltnew(TMPEEG,.1,[]);

%% Epoching and trial rejections
epochEEG = pop_epoch( TMPEEG, { 'S 10' },[0 4.670], 'newname', 'epoch data', 'epochinfo', 'yes');

if s_num==5 && sess==2; epochEEG=pop_rejepoch(epochEEG, [498], 0); end

% reject trials not kept in the log
subj_behavdata_dir=[subj_dir 'log_files/'];
load([subj_behavdata_dir sprintf('subj%i_sess%i_behav_trials_to_rej.mat',s_ind,session)]);
if size(rej_behav_trials,1)~=size(epochEEG.data,3)
    fprintf('INCONSISTENCY BETWEEN NUMBER OF EEG AND LOG TRIALS !!!!!\n');
    return;
else epochEEG=pop_rejepoch(epochEEG, ~rej_behav_trials, 0);
end

epochEEG = eeg_checkset( epochEEG );
epochEEG = pop_rmbase( epochEEG, [0 600]);

% manual trial rejection
eeg_trials_torej_file=sprintf('%ss%i_sess%i_eeg_trials_to_rej.mat',subj_eeg_dir, s_ind, session);
if exist(eeg_trials_torej_file, 'file')
    % load the manually rejected trials
    load(eeg_trials_torej_file);
else
    % or if they dont exist do the manual rejection
    eegplot(epochEEG.data, 'srate',256, 'eloc_file', chanfile,'limits',[-600 3070],...
        'command', 'close', 'events', epochEEG.event);
    waitfor(gcf);
    eegtrialrej=sort(ceil((TMPREJ(:,1)+1)./size(epochEEG.data,2))');
    save(eeg_trials_torej_file, 'eegtrialrej')
end

epochEEGclean=pop_rejepoch(epochEEG, eegtrialrej, 0);

epochEEG = pop_saveset(epochEEGclean,'filename',...
    sprintf('subj%i_session%i_clean.set',s_ind,session),...
    'filepath', subj_eeg_dir);

% datt=epochEEG.data;
% save('/Users/mehdisenoussi/decatsy/decatsy_data/subj3/eeg_files/subj3_sess2_dataclean.mat','datt')




