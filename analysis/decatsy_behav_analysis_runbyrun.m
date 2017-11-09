%% Run-by-run

%% Identify participant and session
s_ind=8; sess=2;

%% Step 1: get the list of files
indir='./decatsy_data/';
subj_dir=[indir 'subj' num2str(s_ind)];
log_dir=[subj_dir '/log_files/sess' num2str(sess) '/eeg/'];
listing = dir([log_dir '*.txt']);
if isempty(listing)
    fprintf('NO FILES IN DIRECTORY'); return;
end    

%% Loop across runs

dprime_valid = zeros(1,size(listing,1)); %1 line and X raws
dprime_invalid = zeros(1,size(listing,1));
RTvalid = zeros(1,size(listing,1)); 
RTinvalid = zeros(1,size(listing,1)); 
for iRun = 1:size(listing,1)
    arg = listing(iRun).name ;
    [dpV,dpI,RTv,RTi]=decatsy_behav_analysis_H421(s_ind, sess, arg); 
    dprime_valid(1,iRun) = dpV;
    dprime_invalid(1,iRun) = dpI;
    RTvalid(1,iRun) = RTv;
    RTinvalid(1,iRun) = RTi;  
    
    disp(['The dprime value of Valid is ' num2str(dpV) ' and Invalid is ' num2str(dpI) '.'])
end

%% Compute the difference between Valid and Invalid

diff = dprime_valid - dprime_invalid;

%% Plot run by run
figure;
hold on;
xlabel('Run');
ylabel('Valid-Invalid');
scatter(1:size(listing,1),diff)
pl = line([0,size(listing,1)],[0,0])
pl.Color = 'black';
pl.LineStyle = '--';
hold off
