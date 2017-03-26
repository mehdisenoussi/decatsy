%% 
clear all; close all;
addpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/')
addpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/plugins/bva-io')
chanfile='63ElecsDescartes.elp';
eeglab('nogui');

%% Some parameters
%dwnSampl = 256; %it's usually better to use higher resolution (512 or 1024)

% read EEG data in dir
% indir='/Users/mehdisenoussi/decatsy/eeg_data/';
% TMPEEG = pop_loadbv(indir, 'decatsy-12-12-16.vhdr');

s_ind=3;
indir='/Volumes/datas/postphd/decatsy/data/Results/';
TMPEEG = pop_loadbv(indir, sprintf('subj%i/s3part1-1.vhdr',s_ind));

% downsampling
TMPEEG = pop_reref(TMPEEG, 1:63, 'refstate', 'averef', 'keepref', 'on');
TMPEEG = pop_chanedit(TMPEEG, 'lookup', ['/Users/mehdisenoussi/decatsy/' chanfile]);

%reference M2
ref.labels = 'M2';
ref.theta = 95;
ref.radius = 0.7222;
ref.X = -0.066765;
ref.Y = -0.76313;
ref.Z = -0.64279;
ref.sph_theta = -95;
ref.sph_phi = 40;
ref.sph_radius = 1;
ref.type = 'EOG';
ref.ref = 'M2';
ref.urchan = [];
ref.datachan = 0;
TMPEEG.chaninfo.nodatchans = ref;

% if subject mehdi_test
elec2change=38;
GoodElectrodesAround_tocheck=[36 3 35 7 6 8 40 41];
TMPEEG.data(elec2change, :) = squeeze(mean(TMPEEG.data(GoodElectrodesAround_tocheck, :)));

elec2change=26;
GoodElectrodesAround_tocheck=[59 27 56 22 55];
TMPEEG.data(elec2change, :) = squeeze(mean(TMPEEG.data(GoodElectrodesAround_tocheck, :)));

elec2change=9;
GoodElectrodesAround_tocheck=[37 6 41 11 42];
TMPEEG.data(elec2change, :) = squeeze(mean(TMPEEG.data(GoodElectrodesAround_tocheck, :)));

elec2change=61;
GoodElectrodesAround_tocheck=[2 28 29 39 58];
TMPEEG.data(elec2change, :) = squeeze(mean(TMPEEG.data(GoodElectrodesAround_tocheck, :)));

% Remove baseline
TMPEEG = pop_rmbase(TMPEEG, [], 1:size(TMPEEG.data,2));


%TMPEEG = pop_eegfilt(TMPEEG, 45, 55, [], [1]);
TMPEEG=pop_eegfiltnew(TMPEEG,48,52,[],1);
TMPEEG = pop_eegfilt(TMPEEG, .1, 0);


%%
epochEEG = pop_epoch( TMPEEG, { 'S 10' },[0 3.67], 'newname', 'epoch data', 'epochinfo', 'yes');
epochEEG = eeg_checkset( epochEEG );

% manual trial rejection
% ...

epochEEGclean = pop_rejepoch( epochEEG, [2 18 31 35 36 38 39 43 45 47 50 51 52 54 55 67 68 70 71 72 81 82 88 147 156 168 171 173 174:177 181 188 189:191 196 198:2:200] ,0);

epochEEG = pop_rmbase( epochEEG, [0 600]);
epochEEG = pop_saveset(epochEEG,'filename','decatsy_test_subj3_part1.set','filepath', indir);
%clear('epochEEG')






