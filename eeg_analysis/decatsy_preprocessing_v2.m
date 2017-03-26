%% 
addpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/')
chanfile='63ElecsDescartes.elp';
eeglab; close;

%% Read EEG data in dir
s_ind=3; session=1;

indir='~/decatsy/eeg_data/Results/';
subj_dir=[indir sprintf('subj%i/',s_ind)];
TMPEEG = pop_loadset('filename',sprintf('s%i_session%i.set',s_ind,session),...
    'filepath', subj_dir);

%% Electrode Replace
rplc=0; channel2rplc = [];
if rplc; TMPEEG = pop_interp(TMPEEG, channel2rplc, 'spherical'); end

%% Remove baseline and filter
TMPEEG = pop_rmbase(TMPEEG, [], 1:size(TMPEEG.data,2));
% Remove electrical line noise
TMPEEG=pop_eegfiltnew(TMPEEG,48,52,[],1);
% remove very slow drifts
TMPEEG=pop_eegfiltnew(TMPEEG,.1,[]);

%% Epoching and trial rejections
epochEEG = pop_epoch( TMPEEG, { 'S 10' },[0 3.67], 'newname', 'epoch data', 'epochinfo', 'yes');

% reject trials not kept in the log
subj_behavdata_dir=[subj_dir 'log_files/'];
load([subj_behavdata_dir sprintf('subj%i_sess%i_behav_trials_to_rej.mat',s_ind,session)]);
if size(rej_behav_trials,1)~=size(epochEEG.data,3)
    fprintf('INCONSISTENCY BETWEEN NUMBER OF EEG AND LOG TRIALS !!!!!')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % how do we exit a script ?? %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
else
    epochEEG=pop_rejepoch(epochEEG, ~rej_behav_trials);
end

epochEEG = eeg_checkset( epochEEG );
epochEEG = pop_rmbase( epochEEG, [0 600]);

% manual trial rejection
if ~exist([subj_dir sprintf('subj%i_sess%i_behav_trials_to_rej.mat',s_ind,session)])
else
    eegtrialrej=eegplot(epochEEG);
    save([],'eegtrialrej')
end
%trial rejected by eye check
%subj3-sess1
% rejtrials_man=[1 11 54 104 106 119 133 192 193 199 211 213 214 215 226 229 233 234 238 239 249 250 303 305 317 321 346 402 449 456 472 477 483 549 556 576 603 628 632 642 651 661 670 673 680 692 718 720 721 734 768];
%subj3-sess2
rejtrials_man=[5 6 14 18 23 26 27 64 65 69 87 92 98 104 109 124 133 135 144 146 151 169 176 188 192 199 201 203 207 212 216 238 241 246 262 272 276 278 279 285 288 289 294 295 297 300 306 319 323 340 341 345 352 365 368 388 397 406 437 462 467 492 494 496 526 527 530 532 538 539 558 562 567 568 571 577 581 582 583 590 596 598 604 616 644 645 653 654 655 657 666 699 702 703 707 708 718 725 735 747 755 770];
epochEEGclean = pop_rejepoch( epochEEG, eegtrialrej,0);

epochEEG = pop_saveset(epochEEGclean,'filename',...
    sprintf('subj%i_session%i_clean.set',s_ind,session),...
    'filepath', subj_dir);
% clear('epochEEG')






