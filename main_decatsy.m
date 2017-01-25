% This script launches the main experiment script
% Sets up Screen, EEG, Eyetracker, experimental design and stim display

% parameters: subject ID, triggers (boolean), eyetracker (boolean), CL phase (1-4),
% observer's group (1-4),

% Clear the workspace and the screen
sca; close all; clearvars;
addpath('./eyetrack-tools-master/')
addpath('./decatsy_funs/')
%addpath('/Users/mehdisenoussi/Dropbox/postphd/decatsy/code/')
%addpath(genpath('C:\Laura\eyetrack-tools-master'))

% default variables
s_ind=0; subjGroup=2; session=2; expPhase='train1'; block=1;
fullscreen=1; useScreenCalib=1;

subjFolder=sprintf('./Results/subj%i',s_ind);
if ~exist(subjFolder,'file'); mkdir(subjFolder); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting up the screen
[window, pixindeg, diffWandG, grey, xCenter, yCenter, ifi, screenYpixels] =...
    screen_init(useScreenCalib, fullscreen);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize Eyetracker and EEG
mainvar.EEG = 1; % is the EEG connected?
mainvar.EL = 1; % is eyelink connected?

% EEG
if mainvar.EEG
    [object, port, portstatus] = initializePort(255);
    % EEG triggers
    mainvar.eOnsetFix = 10; % fixation onset
    mainvar.ePrecue = 20; % precue display
    mainvar.eISI1 = 30; % start ISI1
    mainvar.eCueStim = 40; % response cue and stim display
    mainvar.eISI2 = 50; % start ISI2
    mainvar.eRespPeriod = 60; % start response period and feedback
    mainvar.eResponse = 70; % key press by subject
    mainvar.eITI = 80; % start of ITI period
    mainvar.eFixBreak = 99; % fixation break
end

% Eyetracker
eyeDataDir = 'eyedata';
if mainvar.EL
    eyeFileNum=1;
    eyeFile = sprintf('%s_%s_%i', num2str(s_ind),datestr(now, 'ddmm'),eyeFileNum); %
    while exist(eyeFile, 'file')
        eyeFileNum=eyeFileNum+1;
        eyeFile = sprintf('%s_%s_%i', num2str(s_ind),datestr(now, 'ddmm'),eyeFileNum); %
    end
    eyeFixRad=1.5; % radius of allowable eye movement in pixels
    rad = eyeFixRad/pixindeg;
    % Initialize eye tracker
    [el, exitFlag] = rd_eyeLink('eyestart', window, eyeFile);
    if exitFlag; return; end
    % Calibrate eye tracker
    [cal, exitFlag] = rd_eyeLink('calibrate', window, el);
    if exitFlag; return; end   
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize timings and some task parameters

stims.periodPerDegree=3; stims.sizeInDeg=3;
stims.xDistFix=6; stims.yDistFix=2.5;
cueOrientations=[0,45];
stimPos=[{'left'}; {'right'}]; stimFeat=[{'vert'}; {'hori'}];
% setting up tiltLvls here because for train1 phase we want 0 tilt
tiltLvls=[12 12]; minTiltsLvl=.5; maxTiltsLvl=30; tiltSteps=[3 3];
staircase=0; % except for phase 3 of the training
switch expPhase
    case 'train1' % phase 1 of training: no tilt, just learning associations
        timing.beginTrial=.600; timing.precue=0; timing.ISI1=0; timing.stimPres=1.;
        timing.ISI2=.00; timing.responseTime=2.0; timing.ITIs=.400:.1:1.400;
        n_trials=5; tiltLvls=[0 0];
    case 'train2' % phase 2 of training: easy settings, learning trial event sequence and keys
        timing.beginTrial=.600; timing.precue=.250; timing.ISI1=2;
        timing.stimPres=.500; timing.ISI2=.900; timing.responseTime=.800;
        timing.ITIs=.400:.1:1.400;
        n_trials=5;
    case 'train3' % phase 3 of training: staircase, main task/real conditions
        timing.beginTrial=.600; timing.precue=.120; timing.ISI1=2; timing.stimPres=.050;
        timing.ISI2=.900; timing.responseTime=.800; timing.ITIs=.400:.1:1.400;
        n_trials=5; staircase=1;
    case {'train4', 'main'} % phase 4 of training and main task: real conditions with staircased tilt
        timing.beginTrial=.600; timing.precue=.120; timing.ISI1=2; timing.stimPres=.050;
        timing.ISI2=.900; timing.responseTime=.800; timing.ITIs=.400:.1:1.400;
        n_trials=10;
        load(sprintf('%s/subj%i_cond_%s_staircase_tiltlvls.mat',subjFolder,s_ind,condition));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize cue-stimulus associations, response keys, validity ratio and
% stimuli parameters

[condition, cueStimAsso, leftResps, rightResps, responseKeys, validRatio, stims] =...
    init_cueStimAsso_keys_stimParams(subjGroup, session, expPhase, stims);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%n_trials=10; % TAKE ME OUT FOR THE REAL EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make trial structure
trials = make_trials_struct(n_trials, cueOrientations, validRatio, timing);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decatsy core script call
tiltLvls = decatsy_core(s_ind, subjGroup, session, condition, expPhase, block,...
    mainvar, n_trials, cueStimAsso, leftResps, rightResps, responseKeys,...
    stims, timing, trials, staircase, tiltLvls, tiltSteps, window, pixindeg,...
    diffWandG, grey, xCenter, yCenter, ifi, screenYpixels, stimFeat, el, rad...
    ,object, port);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% saves the staircase tilt levels if in phase 3 of training
if strcmp(expPhase, 'train3')
    save(sprintf('%s/subj%i_cond_%s_staircase_tiltlvls.mat',subjFolder,s_ind,condition), 'tiltLvls')
end



%% Wrap up: Save the eye data, shut down the eye tracker and close the log file
if mainvar.EL
    if ~exist(eyeDataDir,'dir')
        mkdir(eyeDataDir)
    end
    rd_eyeLink('eyestop', window, {eyeFile, eyeDataDir});
end

fclose('all'); % close log file

% End of the experiment, wait for a key press
DrawFormattedText(window, 'Thanks for participating!\nYou are now FREE :)',...
    'center', screenYpixels * 0.25, [1 1 1]);
Screen('Flip', window);

KbStrokeWait;
sca;
