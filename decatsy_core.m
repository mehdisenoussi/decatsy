% Core script of DECATSY experiment
% Sets up Screen, EEG, Eyetracker, experimental design and stim display

% Clear the workspace and the screen
sca; close all; clearvars;
addpath('/Users/mehdisenoussi/Dropbox/postphd/decatsy/code/eyetrack-tools-master/')

Screen('Preference','SkipSyncTests', 1) 
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens'); screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber); black = BlackIndex(screenNumber);
grey = white / 2; diffWandG = abs(white - grey);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DO GAMMA TABLE STUFF HERE !
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, []); %use [] for full screen or [0,0,800,400] for a smaller screen
% [window, windowRect] = Screen('OpenWindow',screenNumber, grey, [0,0,800,400]);

% Get the size of the on screen window in pixels and cm
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[width, height]=Screen('DisplaySize', screenNumber);
ifi = Screen('GetFlipInterval', window);
[xCenter, yCenter] = RectCenter(windowRect);

% Get size of pixel in degree. d is distance of observer to screen
d=57; pixincm=width/10/screenXpixels;
pixindeg=360/pi*tan(pixincm/(2*d));

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); 

topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% initialize some variables for the Eyelink init
display.dist = 57; % 50;                                      % viewing distance (cm)
display.width = 40; % 30; %%% desktop                        % width of screen (cm)


display.screenNum = screenNumber;
if display.screenNum > 1; display.screenNum = 2; end
display.bkColor = round([255 255 255]/4);
display.fgColor = display.bkColor*2; 


%% File settings

s_ind=1; dateLaunch=datestr(now, 30); 
filename=['Results/Subj-' num2str(s_ind), '-' dateLaunch '.txt'];
fid=fopen(filename,'w');
fprintf(fid,'s_ind\tsession\tphase\tcondition\ttrial\trespTime\trespKey\tcorrectResp\tcorrectSide\tcorrectTilt\tcue\tprecue\tvalidity\ttiltLvlVert\ttiltLvlHori\ttiltStepVert\ttiltStepHori\tgratingOriLeft\tgratingOriRight\n');

eyeDataDir = 'eyedata';

%% EEG and Eyetracker setup
% is the EEG connected?
mainvar.EEG = 0;
% is eyelink connected?
mainvar.EL = 0;

if mainvar.EEG
    [object, port, portstatus] = initializePort(255);
end

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

if mainvar.EL
    eyeFileNum=1;
    eyeFile = sprintf('%s_%s_%i', num2str(s_ind),datestr(now, 'ddmm'),eyeFileNum); %
    while exist(eyeFile)
        eyeFileNum=eyeFileNum+1;
        eyeFile = sprintf('%s_%s_%i', num2str(s_ind),datestr(now, 'ddmm'),eyeFileNum); %
    end
    
    eyeFixRad=1.5; % radius of allowable eye movement in pixels
    rad = eyeFixRad/pixindeg;
    
    % Initialize eye tracker
    [el exitFlag] = rd_eyeLink('eyestart', window, eyeFile);
    if exitFlag
        return
    end
    
    % Calibrate eye tracker
    [cal exitFlag] = rd_eyeLink('calibrate', window, el);
    if exitFlag
        return
    end    
end

%% Fixation and cue
% Define a squared matrix of zeros
sizesq=round(.7/pixindeg);
baseRect = [0 0 sizesq sizesq];
squa = zeros(sizesq,sizesq);
squaTexture = Screen('MakeTexture', window, squa);
distFromFixDeg=2; distFromFixPix=distFromFixDeg/pixindeg;
dstRect = CenterRectOnPointd(baseRect, xCenter, yCenter-distFromFixPix);
cueOrientations=[0,45];
% Nearest neighbour for Screen('Drawlines') filtering
filterMode = 0;

% Define central cross
fixSizeDeg=.2; fixCrossDimPix = round(fixSizeDeg/2/pixindeg);
xCoords = [-fixCrossDimPix fixCrossDimPix-1 fixCrossDimPix-1 -fixCrossDimPix];
yCoords = [-fixCrossDimPix fixCrossDimPix -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords]; lineWidthPix = 2;


%% Grating
stims.contrast=.15; stims.sizeInDeg=3; stims.periodPerDegree=3;
stims.xDistFix=6; stims.yDistFix=2.5;

grayscaleImageMatrixL=make_gratingMat(diffWandG,grey,pixindeg,...
                        0,stims.periodPerDegree,stims.sizeInDeg);
grayscaleImageMatrixR=make_gratingMat(diffWandG,grey,pixindeg,...
                        0,stims.periodPerDegree,stims.sizeInDeg);
texGabL=Screen('MakeTexture', window, grayscaleImageMatrixL);
texGabR=Screen('MakeTexture', window, grayscaleImageMatrixR);

% Specify gabor locations
coordclg=[stims.xDistFix/pixindeg,stims.yDistFix/pixindeg];
gaborDimPix=round(stims.sizeInDeg/pixindeg);
stims.gabLocL = [(xCenter-coordclg(1))-gaborDimPix/2 (xCenter-coordclg(1))+gaborDimPix/2;...
            (yCenter+coordclg(2))-gaborDimPix/2 (yCenter+coordclg(2))+gaborDimPix/2];
stims.gabLocR = [(xCenter+coordclg(1))-gaborDimPix/2 (xCenter+coordclg(1))+gaborDimPix/2;...
            (yCenter+coordclg(2))-gaborDimPix/2 (yCenter+coordclg(2))+gaborDimPix/2];


%% Experiment variables (e.g. timing etc.)

n_trials=2;

staircase=true;
% reversals holds trial numbers when a reversal in the staircase occured
if staircase
    reversals=zeros(2,n_trials);
    tiltChanges=zeros(2,n_trials);
    lastTiltChange=[0 0];
end

% indicates if it's the 1st or 2nd session for the subject (there should be
% two: a feature session and a spatial session (each with 4 training and
% 1 main phases)
session='1';
% this variable indicates which phase of the session the subject is
% performing. the phases are: train1, train2, train3, train4 and main
expPhase='train1';

leftResps=[{'q'} {'s'}]; rightResps=[{'k'} {'l'}];
validRatio=.7;
condition='spatial';
stimPos=[{'left'}; {'right'}]; stimFeat=[{'vert'}; {'hori'}];
switch condition
    case 'feature'
        cueStimAsso=[{'hori'}; {'vert'}];
    case 'spatial'
        cueStimAsso=[{'left'}; {'right'}];
end

timing.beginTrial=.100;
timing.precue=.120;
timing.ISI1=2;
timing.stimPres=.040;
timing.ISI2=.900;
timing.responseTime=.800;
timing.ITIs=.900:.1:1.900;

% timing.beginTrial=.0100;
% timing.precue=.0120;
% timing.ISI1=.002;
% timing.stimPres=.0040;
% timing.ISI2=.00900;
% timing.responseTime=.00800;
% timing.ITIs=.0900:.01:.200;

% trials.verhor=[repmat([0 90],1,ceil(n_trials/2)); repmat([0 90],1,ceil(n_trials/2))];
trials.verhor=repmat([0 90]',1,n_trials);
% tilt is randomly the same on the two gratings
trials.tiltsLvl=[12 12]; trials.mintiltsLvl=.5; trials.maxtiltsLvl=30;
trials.tiltSteps=[3 3]; trials.minTiltStep=.2;
trials.tiltDir=[Shuffle(repmat([-1 1],1,n_trials));...
    Shuffle(repmat([-1 1],1,n_trials))]; %[-ones(1,n_trials/2) ones(1,n_trials/2)];
trials.validity=zeros(1, n_trials);
trials.validity(1:round(validRatio*n_trials))=1;
trials.precue=repmat(cueOrientations, 1, ceil(n_trials/2));
trials.cue=repmat(cueOrientations, 1, ceil(n_trials/2));
trials.cue(~logical(trials.validity))=(~trials.cue(~logical(trials.validity)))*45;
trials.ITI=timing.ITIs(randi(11,1,n_trials));

% shuffling trials
shuffIndex=randi(n_trials,1,n_trials);
trials.verhor=Shuffle(trials.verhor); %trials.verhor=trials.verhor(:,shuffIndex);
trials.cue=trials.cue(shuffIndex); trials.precue=trials.precue(shuffIndex);
trials.validity=trials.validity(shuffIndex);

%% Presentation of the stimuli
triali=1; fixation=1;

% Draw text in the upper portion of the screen with the default font
Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
Screen('TextSize', window, 30);
DrawFormattedText(window, 'Type any key to begin trial', 'center',...
    screenYpixels * 0.25, [1 1 1]);
Screen('Flip', window);
KbStrokeWait;
Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
Screen('Flip', window);

while triali <= n_trials
    continueTrial=1;
    while continueTrial
        % start the trial when the eyetracker is recording and the subject 
        % is fixating
        if mainvar.EL
            rd_eyeLink('trialstart', window, {el, triali, xCenter, yCenter, rad})
            Eyelink('Message', 'TRIAL_START');
        end

        % beginning of the trial: fixation cross
        if mainvar.EEG; sendEventCode(object,port, mainvar.eOnsetFix); end
        WaitSecs(timing.beginTrial);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % pre-cue: fixation cross and pre-cue
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firstPass=1; tempT=GetSecs;
        while GetSecs < tempT+timing.precue
            Screen('DrawTextures', window, squaTexture, [], dstRect, trials.precue(triali), filterMode);
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip',window);
            if mainvar.EEG && firstPass
                sendEventCode(object,port, mainvar.ePrecue);
                firstPass=0;
            end
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % ISI 1: fixation cross
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firstPass=1; tempT=GetSecs;
        while GetSecs < tempT+timing.ISI1
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip',window);
            if mainvar.EL
                fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                if ~fixation
                    fprintf('\nBROKE FIXATION! (trial %i)',triali)
                    Beeper('low'); break;
                end
            end
            if firstPass
                if mainvar.EEG; sendEventCode(object,port, mainvar.eCueStim); end
                if mainvar.EL; Eyelink('Message', 'EVENT_STIM'); end
                firstPass=0;
            end
        end        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stimuli: fixation cross, cue and stimuli
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%
        % NEED TO CHANGE THE trialsTiltslvl because now its interpreting the 1
        % and 2 of the array as the left and right and actually its the hori
        % and vert
        %
        % DONE - NEED TO CHECK
        %%%%%%%%%%%%%%%%%%%%%%%%
        firstPass=1; tempT=GetSecs;
        while GetSecs < tempT+timing.stimPres
            if trials.verhor(1,triali)
                gratingOri=[trials.verhor(1,triali)+(trials.tiltsLvl(2)*trials.tiltDir(2,triali)),...
                    trials.verhor(2,triali)+(trials.tiltsLvl(1)*trials.tiltDir(1,triali))];
            else
                gratingOri=[trials.verhor(1,triali)+(trials.tiltsLvl(1)*trials.tiltDir(1,triali)),...
                    trials.verhor(2,triali)+(trials.tiltsLvl(2)*trials.tiltDir(2,triali))];
            end
            Screen('DrawTextures', window, texGabL, [], stims.gabLocL,...
                gratingOri(1), filterMode, stims.contrast);
            Screen('DrawTextures', window, texGabR, [], stims.gabLocR,...
                gratingOri(2), filterMode, stims.contrast);
            Screen('DrawTextures', window, squaTexture, [], dstRect, trials.cue(triali), filterMode);
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip', window);
            
            if mainvar.EL
                fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                if ~fixation
                    fprintf('\nBROKE FIXATION! (trial %i)',triali)
                    Beeper('low'); break;
                end
            end
            if firstPass
                if mainvar.EEG; sendEventCode(object,port, mainvar.eCueStim); end
                if mainvar.EL; Eyelink('Message', 'EVENT_STIM'); end
                firstPass=0;
            end
        end
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % ISI 2: fixation cross and cue
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firstPass=1; tempT=GetSecs;
        while GetSecs < tempT+timing.ISI2
            Screen('DrawTextures', window, squaTexture, [], dstRect, trials.cue(triali), filterMode);
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip',window);
            if mainvar.EL
                fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                if ~fixation
                    fprintf('\nBROKE FIXATION! (trial %i)',triali)
                    Beeper('low'); break;
                end
            end
            if firstPass
                if mainvar.EEG; sendEventCode(object,port, mainvar.eCueStim); end
                if mainvar.EL; Eyelink('Message', 'EVENT_ISI2'); end
                firstPass=0;
            end
        end
        Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
        Screen('Flip', window);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % response and feedback
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        FlushEvents('keyDown');
        keyIsDown=0; waitRespFrame=0; responded=0; respFixCol=[0 0 0];keyCode=[];
        timeDisp=GetSecs;
        if mainvar.EEG; sendEventCode(object,port, mainvar.eRespPeriod); end
        while waitRespFrame<(timing.responseTime/ifi)
            Screen('DrawLines', window, allCoords, lineWidthPix, respFixCol, [xCenter yCenter], 0);
            Screen('Flip',window);
            if not(responded)
                [keyIsDown, keyTime, keyCode] = KbCheck;
                keyTemp=KbName(keyCode);
                if keyIsDown && sum(strcmp(keyTemp(1), [leftResps rightResps]))
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eResponse); end
                    responded=1;
                    respTrials(triali).respTime=keyTime-timeDisp;
                    responseKey=KbName(keyCode);
                    respTrials(triali).respKey=responseKey;
                    respTrials(triali).cue=trials.cue(triali);
                    respTrials(triali).precue=trials.precue(triali);
                    respTrials(triali).validity=trials.validity(triali);
                    switch condition
                        case 'feature'
                            % if feature condition find out which cue it is, 
                            % then which orientation the cue is associated with
                            % then where this orientation was (left or right)
                            targetFeat=cueStimAsso(logical(trials.cue(triali))+1);
                            if strcmp(targetFeat, 'hori')
                                if trials.verhor(1,triali)==90;targetPos='left';
                                else targetPos='right'; end
                            elseif strcmp(targetFeat, 'vert')
                                if trials.verhor(1,triali)==0;targetPos='left';
                                else targetPos='right'; end
                            end
                        case 'spatial'
                            % if spatial condition find out which cue it is to get
                            % which side it is associated with
                            targetPos=cueStimAsso(logical(trials.cue(triali))+1);
                            if strcmp(targetPos,'left');
                                targetFeat=stimFeat(logical(trials.verhor(1,triali))+1);
                            else targetFeat=stimFeat(logical(trials.verhor(2,triali))+1);
                            end
                    end
                    respTrials(triali).targetFeat=targetFeat;
                    respTrials(triali).targetPos=targetPos;

                    % once we know where the target was, we rate if the pressed 
                    % key was on the correct side
                    if sum(strcmp(leftResps, responseKey)); respTrials(triali).respSide='left'; 
                    else sum(strcmp(rightResps, responseKey)); respTrials(triali).respSide='right'; end
                    respTrials(triali).correctSide=strcmp(targetPos, respTrials(triali).respSide);

                    % if the observer responded on the correct side, check if he
                    % reported the correct tilt
                    if respTrials(triali).correctSide
                        if strcmp(targetPos, 'left')
                            switch trials.tiltDir(1,triali)
                                case -1
                                    respTrials(triali).correctTilt=strcmp(responseKey,leftResps(1));
                                case 1
                                    respTrials(triali).correctTilt=strcmp(responseKey,leftResps(2));
                            end
                        else
                            switch trials.tiltDir(2,triali)
                                case -1
                                    respTrials(triali).correctTilt=strcmp(responseKey,rightResps(1));
                                case 1
                                    respTrials(triali).correctTilt=strcmp(responseKey,rightResps(2));
                            end
                        end
                    else respTrials(triali).correctTilt=-1;
                    end
                    respTrials(triali).correctResp=...
                        respTrials(triali).correctTilt==1 && respTrials(triali).correctSide;
                    if respTrials(triali).correctResp; respFixCol=[0 1 0];                
                    else respFixCol=[1 0 0]; end
                else
                    respTrials(triali).correctResp=0;
                end
            end
            waitRespFrame=waitRespFrame+1;
        end
        continueTrial=0;
    end
    

    if ~fixation
        breakFixTxt=cat(2,'Please fixate!');
        DrawFormattedText(window,breakFixTxt,'center', screenYpixels * 0.25, [1 1 1]);
        Screen('Flip', window); WaitSecs(1);
        fprintf(fid, '%i\t%s\t%s\t%i\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
        s_ind, session, expPhase, triali,'fixBreak',-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5);
    else
        Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
        Screen('Flip', window);
        if responded
            % s_ind-session-phase-condition-trial-respTime-respKey-correctSide
            % correctResp-cue-precue-validity-correctSide-correctTilt-correctResp
            % -tiltLvlHori-tiltLvlVert-tiltStepHori-tiltStepVert-gratingOriL-gratingOriR
            fprintf(fid,'%i\t%s\t%s\t%s\t%i\t%.4f\t%s\t%i\t%i\t%i\t%i\t%i\t%i\t%i\t%i\t%d\t%d\t%d\t%d\t%.2f\t%.2f\n\n',...
                s_ind, session, expPhase, condition, triali, respTrials(triali).respTime,...
                respTrials(triali).respKey,  respTrials(triali).correctResp,...
                respTrials(triali).correctSide, respTrials(triali).correctTilt,...
                respTrials(triali).cue, respTrials(triali).precue, respTrials(triali).validity,...
                trials.tiltsLvl, trials.tiltSteps, gratingOri);
            fprintf(fid,'\n');
        else
            fprintf(fid, '%i\t%s\t%s\t%i\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
                s_ind, session, expPhase, triali,'notResponded',-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5);
            Beeper('low');
        end
    
        %%%%%%%%%%%%%
        % Staircase %
        %%%%%%%%%%%%%
        if staircase && triali>1 && responded
            % if it is not the first trial, if we are doing a staircase and if
            % the observer responded in this trial        
            if strcmp(targetFeat, stimFeat(1)); targetFeatInd=1;
            else targetFeatInd=2; end
            tilt=trials.tiltsLvl(targetFeatInd);

            if not(sum(reversals(targetFeatInd,:)))
                % 1st reversal do simple one-up-one-down
                if respTrials(triali).correctResp; tiltSign=-1;
                else tiltSign=1; end
                tilt=tilt+(tiltSign*trials.tiltSteps(targetFeatInd));
                trials.tiltsLvl(targetFeatInd)=tilt;
                tiltChanges(targetFeatInd, triali)=tiltSign;
                if tiltChanges(targetFeatInd,triali)==-lastTiltChange(targetFeatInd)
                    reversals(targetFeatInd,triali)=1;
                    trials.tiltSteps(targetFeatInd)=trials.tiltSteps(targetFeatInd)/2.;
                end
                lastTiltChange(targetFeatInd)=tiltSign;
            else
                tiltSign=0;
                % not 1st reversal: one-up-two-down
                if not(respTrials(triali).correctResp)
                   tiltSign=1; % one-up -> increase tiltLvl
                elseif respTrials(triali).correctResp && respTrials(triali-1).correctResp
                    tiltSign=-1; % two-down -> decrease tiltLvl
                end
                tilt=tilt+(tiltSign*trials.tiltSteps(targetFeatInd));

                % stores the new tilt if it doesn't exceed the tilt limits
                if tilt>trials.mintiltsLvl && tilt<trials.maxtiltsLvl
                    fprintf('\ntiltlvl changed %i\n',tiltSign);
                    trials.tiltsLvl(targetFeatInd)=tilt;
                    tiltChanges(targetFeatInd, triali) = tiltSign;

                    % if there is a reversal in this feature's tiltChange
                    if tiltSign==-lastTiltChange(targetFeatInd)
                        reversals(targetFeatInd,triali)=1;
                        % takes care of the Levitt rule
                        if mod(length(find(reversals(targetFeatInd,:)~=0)),2)
                            % if the reversal number is odd divide tiltStep by 2
                            newTiltStep=trials.tiltSteps(targetFeatInd)/2.;
                            % no minimum for tilt step
                            trials.tiltSteps(targetFeatInd)=newTiltStep;
    %                         if newTiltStep>trials.minTiltStep
    %                             trials.tiltSteps(targetFeatInd)=newTiltStep;
    %                         end
                        end
                    end
                    if tiltSign; lastTiltChange(targetFeatInd)=tiltSign; end
                end
            end
        end
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ITI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    firstPass=1; tempT=GetSecs;
    while GetSecs < tempT+trials.ITI(triali)
        if mainvar.EL
            fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
            if ~fixation
                fprintf('\nBROKE FIXATION! (trial %i)',triali)
                Beeper('low')
                break;
            end
        end
        if firstPass
            if mainvar.EEG; sendEventCode(object,port, mainvar.eITI); end
            if mainvar.EL; Eyelink('Message', 'START_ITI'); end
            firstPass=0;
        end
    end
    triali=triali+1;
end

% End of the experiment, wait for a key press
fclose('all');
DrawFormattedText(window, 'Thanks for participating!\nYou are now FREE :)',...
    'center', screenYpixels * 0.25, [1 1 1]);
Screen('Flip', window);

% Save the eye data and shut down the eye tracker
if mainvar.EL
    if ~exist(eyeDataDir,'dir')
        mkdir(eyeDataDir)
    end
    rd_eyeLink('eyestop', window, {eyeFile, eyeDataDir});
end

KbStrokeWait;
sca;

