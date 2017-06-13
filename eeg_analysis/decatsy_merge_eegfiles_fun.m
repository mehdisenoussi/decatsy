%% 
function [] = decatsy_merge_eegfiles_fun(s_num, sess)
    addpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/');
    chanfile='63ElecsDescartes.elp';
    eeglab; close;
    addpath(genpath('/Users/mehdisenoussi/matlab/eeglab13_6_5b/plugins/bva-io-master/'));

    dwnsmpl=256;
    %% read EEG data in subject directory and merge the datasets
    indir='./decatsy_data/';
    %indir='/Volumes/datas/postphd/decatsy/data/';
    subj_eeg_dir=[indir sprintf('subj%i/eeg_files/',s_num)];
    subj_eegsess_dir=[subj_eeg_dir sprintf('sess%i/',sess)];
    listing = dir([subj_eegsess_dir '*.vhdr']);
    if isempty(listing); fprintf('NO FILES IN DIRECTORY'); return;
    else
        blocknums=zeros(1,size(listing,1));
        for part=1:size(listing,1)
            temp=strsplit(listing(part).name, {'-','.'});
            blocknums(part)=str2num(temp{2});
        end
        rootfilename=temp{1};
        blocknums=sort(blocknums);
        for block=blocknums
            filename=sprintf('%s-%i.vhdr',rootfilename,block);
            fprintf(sprintf('loaded file: %s\n',filename));
            %fprintf(sprintf('%s%s',subj_eegsess_dir,filename);
            tmp=pop_loadbv(subj_eegsess_dir, filename);
            if block==1; TMPEEG=tmp;
            else TMPEEG=pop_mergeset(TMPEEG, tmp,0);
            end
        end
    end
    TMPEEG = pop_resample( TMPEEG, dwnsmpl);

    % downsampling
    TMPEEG = pop_reref(TMPEEG, 1:63, 'refstate', 'averef', 'keepref', 'on');
    TMPEEG = pop_chanedit(TMPEEG, 'lookup', [chanfile]);

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

    TMPEEG = pop_saveset(TMPEEG,'filename',sprintf('subj%i_sess%i.set',...
        s_num,sess), 'filepath', subj_eeg_dir);
end


