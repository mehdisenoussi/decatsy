%% 
clear all; close all;
genpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/')
eeglab('nogui');
genpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/plugins/bva-io-master/')
chanfile='63ElecsDescartes.elp';

dwnsmpl=256;
%% read EEG data in subject directory and merge the 3 datasets
s_ind=3; session=2; part=1;
indir='/Volumes/datas/postphd/decatsy/data/Results/';
subj_dir=[indir sprintf('subj%i/',s_ind)];
subj_dir='/Users/mehdisenoussi/decatsy/eeg_data/Results/subj3/s3part2/';
for part=1:3
    tmp=pop_loadbv(subj_dir, sprintf('s%ipart%i-%i.vhdr',s_ind,session,part));
    if part==1; TMPEEG=tmp;
    else TMPEEG=pop_mergeset(TMPEEG, tmp,0);
    end
end

TMPEEG = pop_resample( TMPEEG, dwnsmpl);

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

TMPEEG = pop_saveset(TMPEEG,'filename',sprintf('s%i_session%i.set',...
    s_ind,session), 'filepath', subj_dir);