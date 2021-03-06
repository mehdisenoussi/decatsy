% Core script of DECATSY experiment
% This script mainly loops for the different trials, processes the
% response, sends the EEG and EL triggers and writes in the log file.
function [tiltLvls, tiltHistory] = decatsy_core(s_ind, subjGroup, session, condition, expPhase, block,...
    mainvar, n_trials, cueStimAsso, leftResps, rightResps, responseKeys,...
    stims, timing, trials, staircase, tiltLvls, tiltSteps, window, pixindeg,...
    diffWandG, grey, xCenter, yCenter, ifi, screenYpixels, stimFeat, el, rad...
    ,object, port, maxTiltsLvl, minTiltsLvl, minTiltStep)
    
    %% Setting up log file
    dateLaunch=datestr(now, 30);
    filename=sprintf('./Results/subj%i/Subj-%i-%s.txt',s_ind,s_ind,dateLaunch);
    fid=fopen(filename,'w');
    fprintf(fid,['s_ind\tsubjGroup\tsession\tphase\tcondition\tblock\ttrial\trespTime'...
        '\trespKey\tcorrectResp\tcorrectSide\tcorrectTilt\tprecue\tcue\tvalidity'...
        '\ttiltLvlVert\ttiltLvlHori\ttiltStepVert\ttiltStepHori\tgratingOriLeft\t'...
        'gratingOriRight\n']);

    %% Fixation and cue
    % Define a squared matrix of zeros // if in phase train3 make circular cue 
    sizecue=round(.7/pixindeg); halfsc=round(sizecue/2.);
    baseRect = [0 0 sizecue sizecue];
    squa = zeros(sizecue,sizecue);
    if strcmp(expPhase,'train3')
        [x, y] = meshgrid(-halfsc:halfsc, -halfsc:halfsc);
        circleMat = sqrt((x .^ 2) + (y .^ 2)); outerVal=circleMat(halfsc,end);
        circleMat(circleMat<=outerVal)=0; circleMat(circleMat>outerVal)=grey;
        precueTexture=Screen('MakeTexture', window, circleMat);
    else precueTexture=Screen('MakeTexture', window, squa);
    end
    cueTexture = Screen('MakeTexture', window, squa);

    distFromFixDeg=2; distFromFixPix=distFromFixDeg/pixindeg;
    dstRect = CenterRectOnPointd(baseRect, xCenter, yCenter-distFromFixPix);
    filterMode = 0; %Nearest neighb for Screen('Drawlines')

    % Define central cross
    fixSizeDeg=.3; fixCrossDimPix = round(fixSizeDeg/2/pixindeg);
    xCoords = [-fixCrossDimPix fixCrossDimPix-1 fixCrossDimPix-1 -fixCrossDimPix];
    yCoords = [-fixCrossDimPix fixCrossDimPix -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords]; lineWidthPix = 2;


    %% Grating
    % grating stimuli and texture are done at each trial

    % Specify gratings locations
    coordclg=[stims.xDistFix/pixindeg,stims.yDistFix/pixindeg];
    gaborDimPix=round(stims.sizeInDeg/pixindeg);
    stims.gabLocL = [(xCenter-coordclg(1))-gaborDimPix/2 (xCenter-coordclg(1))+gaborDimPix/2;...
                (yCenter+coordclg(2))-gaborDimPix/2 (yCenter+coordclg(2))+gaborDimPix/2];
    stims.gabLocR = [(xCenter+coordclg(1))-gaborDimPix/2 (xCenter+coordclg(1))+gaborDimPix/2;...
                (yCenter+coordclg(2))-gaborDimPix/2 (yCenter+coordclg(2))+gaborDimPix/2];


    %% Experiment variables (e.g. timing etc.)
    if staircase
        % reversals holds trial numbers when a reversal in the staircase occured
        reversals=zeros(2,n_trials);
        tiltChanges=zeros(2,n_trials);
        lastTiltChangeSign=[0 0];
        lastRespondedTrialByFeat=[0 0];
        
    end
    
    %% Presentation of the stimuli
    triali=1; fixation=1;

    % Draw text in the upper portion of the screen with the default font
    Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
    Screen('TextSize', window, 30);
    DrawFormattedText(window, 'Type any key to test the sound.', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    Screen('Flip', window); KbStrokeWait;
    Beeper('medium');
    
    Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
    Screen('TextSize', window, 30);
    DrawFormattedText(window, 'Type any key to start the experiment.', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    Screen('Flip', window); KbStrokeWait;
    
    Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
    Screen('Flip', window);

    while triali <= n_trials
        % Check whether hori-left & vert-right or the inverse, get the
        % angle of the grating for each side and create the 2 textures
        if trials.feature(1,triali)
            gratingOri=[trials.feature(1,triali)+(tiltLvls(2)*trials.tiltDir(2,triali)),...
                trials.feature(2,triali)+(tiltLvls(1)*trials.tiltDir(1,triali))];
        else
            gratingOri=[trials.feature(1,triali)+(tiltLvls(1)*trials.tiltDir(1,triali)),...
                trials.feature(2,triali)+(tiltLvls(2)*trials.tiltDir(2,triali))];
        end
        
        grayscaleImageMatrixL=make_gratingMat(diffWandG,grey,pixindeg,...
                            gratingOri(1),stims.periodPerDegree,stims.sizeInDeg);
        grayscaleImageMatrixR=make_gratingMat(diffWandG,grey,pixindeg,...
                            gratingOri(2),stims.periodPerDegree,stims.sizeInDeg);
        texGabL=Screen('MakeTexture', window, grayscaleImageMatrixL);
        texGabR=Screen('MakeTexture', window, grayscaleImageMatrixR);
        
        continueTrial=1;
        while continueTrial
            % start the trial when the eyetracker is recording and the subject 
            % is fixating
            if mainvar.EL
                rd_eyeLink('trialstart', window, {el, triali, xCenter, yCenter, rad})
                Eyelink('Message', 'TRIAL_START');
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % trial start: fixation cross
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.beginTrial-(ifi/2))
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
                Screen('Flip',window);
                if mainvar.EEG && firstPass
                    sendEventCode(object,port, mainvar.eOnsetFix);
                    if mainvar.EL; Eyelink('Message', 'EVENT_TRIALSTART'); end
                    firstPass=0;
                end
                if mainvar.EL
                    fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                    if ~fixation
                        fprintf('\nBROKE FIXATION! (trial %i)',triali)
                        Beeper('low');
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eFixBreak); end
                        break;
                    end
                end
            end
            if ~fixation; break; end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % pre-cue: fixation cross and pre-cue
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.precue-(ifi/2))
                Screen('DrawTextures', window, precueTexture, [], dstRect, trials.precue(triali), filterMode);
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
                Screen('Flip',window);
                if mainvar.EEG && firstPass
                    sendEventCode(object,port, mainvar.ePrecue);
                    if mainvar.EL; Eyelink('Message', 'EVENT_PRECUE'); end
                    firstPass=0;
                end
                if mainvar.EL
                    fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                    if ~fixation
                        fprintf('\nBROKE FIXATION! (trial %i)',triali)
                        Beeper('low');
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eFixBreak); end
                        break;
                    end
                end
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            end
            if ~fixation; break; end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ISI 1: fixation cross
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.ISI1-(ifi/2))
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
                Screen('Flip',window);
                if firstPass
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eISI1); end
                    if mainvar.EL; Eyelink('Message', 'EVENT_ISI1'); end
                    firstPass=0;
                end
                if mainvar.EL
                    fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                    if ~fixation
                        fprintf('\nBROKE FIXATION! (trial %i)',triali)
                        Beeper('low');
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eFixBreak); end
                        break;
                    end
                end
            end
            if ~fixation; break; end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Stimuli: fixation cross, cue and stimuli
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.stimPres-(ifi/2))
                Screen('DrawTexture', window, texGabL, [], stims.gabLocL,...
                    [], filterMode, stims.contrast);
                Screen('DrawTexture', window, texGabR, [], stims.gabLocR,...
                   [], filterMode, stims.contrast);
                Screen('DrawTexture', window, cueTexture, [], dstRect, trials.cue(triali), filterMode);
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
                Screen('Flip', window);
                if firstPass
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eCueStim); end
                    if mainvar.EL; Eyelink('Message', 'EVENT_STIM'); end
                    firstPass=0;
                end
                if mainvar.EL
                    fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                    if ~fixation
                        fprintf('\nBROKE FIXATION! (trial %i)',triali)
                        Beeper('low');
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eFixBreak); end
                        break;
                    end
                end
            end
            if ~fixation; break; end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ISI 2: fixation cross and cue
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.ISI2-(ifi/2))
                Screen('DrawTexture', window, cueTexture, [], dstRect, trials.cue(triali), filterMode);
                Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
                Screen('Flip',window);
                if mainvar.EL
                    fixation = rd_eyeLink('fixcheck', window, {xCenter, yCenter, rad});
                    if ~fixation
                        fprintf('\nBROKE FIXATION! (trial %i)',triali)
                        Beeper('low');
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eFixBreak); end
                        break;
                    end
                end
                if firstPass
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eISI2); end
                    if mainvar.EL; Eyelink('Message', 'EVENT_ISI2'); end
                    firstPass=0;
                end
            end
            if ~fixation; break; end
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip', window);


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % response and feedback
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            FlushEvents('keyDown');
            keyIsDown=0; waitRespFrame=0; responded=0; respFixCol=[0 0 0];keyCode=[];
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+timing.responseTime-(ifi/2))
                Screen('DrawLines', window, allCoords, lineWidthPix, respFixCol, [xCenter yCenter], 0);
                Screen('Flip',window);
                if firstPass
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eRespPeriod); end
                    if mainvar.EL; Eyelink('Message', 'EVENT_RESP_PERIOD'); end
                    firstPass=0;
                end
                if not(responded)
                    [keyIsDown, keyTime, keyCode] = KbCheck;
                    keyTemp=KbName(keyCode);
                    if keyIsDown && sum(strcmp(keyTemp(1), responseKeys))
                        if mainvar.EEG; sendEventCode(object,port, mainvar.eResponse); end
                        responded=1;
                        respTrials(triali).respTime=keyTime-tempT;
                        responseKey=keyTemp(1);
                        respTrials(triali).respKey=responseKey;
                        [respTrials, respFixCol]=process_resp(respTrials,...
                            trials,triali,condition,expPhase,cueStimAsso,...
                            stimFeat,leftResps,rightResps,responseKey);
                        trialFeat=strcmp(respTrials(triali).targetFeat, stimFeat);
                    else respTrials(triali).correctResp=0;
                    end
                end
            end
            continueTrial=0;
        end


        if ~fixation
            breakFixTxt=cat(2,'Please fixate.');
            DrawFormattedText(window,breakFixTxt,'center', screenYpixels * 0.25, [1 1 1]);
            Screen('Flip', window);
            fprintf(fid, '%i\t%i\t%i\t%s\t%s\t%i\t%i\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
                s_ind, subjGroup, session, expPhase, condition, block, triali,...
                'fixBreak',-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5);
            % If subject broke fixation the trial will be re-presented at
            % the end of the trial sequence
            n_trials=n_trials+1; trials=append_trial(trials,triali);
            WaitSecs(1);
            % add information from the previous trials to avoid staircase
            % looking into an empty structure
            if triali>1 
                respTrials(triali).correctResp=respTrials(triali-1).correctResp;
                respTrials(triali).respKey=respTrials(triali-1).respKey;
                respTrials(triali).respTime=respTrials(triali-1).respTime;
                respTrials(triali).targetFeat=respTrials(triali-1).targetFeat;
                respTrials(triali).targetPos=respTrials(triali-1).targetPos;
                respTrials(triali).correctSide=respTrials(triali-1).correctSide;
                respTrials(triali).correctTilt=respTrials(triali-1).correctTilt;
            end
        else
            Screen('DrawLines', window, allCoords,lineWidthPix,[1 1 1],[xCenter yCenter],0);
            Screen('Flip', window);
            if responded
                % s_ind-subjGroup-session-phase-condition-block-triali-respTime-respKey
                % correctResp-correctSide-correctTilt-precue-cue-validity
                % tiltLvlHori-tiltLvlVert-tiltStepHori-tiltStepVert-gratingOriL-gratingOriR
                fprintf(fid, ['%i\t%i\t%i\t%s\t%s\t%i\t%i\t%.4f\t%s\t%i\t%i\t%i\t' ... % 12
                            '%i\t%i\t%i\t%i\t%i\t%d\t%d\t%d\t%d\n'],...  % 9
                    s_ind, subjGroup, session, expPhase, condition, block, triali,...
                    respTrials(triali).respTime, respTrials(triali).respKey,...
                    respTrials(triali).correctResp, respTrials(triali).correctSide,...
                    respTrials(triali).correctTilt, trials.precue(triali),...
                    trials.cue(triali), trials.validity(triali),...
                    tiltLvls, tiltSteps, gratingOri);
            else
                fprintf(fid, '%i\t%i\t%i\t%s\t%s\t%i\t%i\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',...
                    s_ind, subjGroup, session, expPhase, condition, block, triali,...
                    'notResponded',-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5);
                Beeper('low');
                % If subject did not respond the trial will be re-presented
                % at the end of the trial sequence
                n_trials=n_trials+1; trials=append_trial(trials,triali);
                % add information from the previous trials to avoid staircase
                % looking into an empty structure
                if triali>1
                    respTrials(triali).correctResp=respTrials(triali-1).correctResp;
                    respTrials(triali).respKey=respTrials(triali-1).respKey;
                    respTrials(triali).respTime=respTrials(triali-1).respTime;
                    respTrials(triali).targetFeat=respTrials(triali-1).targetFeat;
                    respTrials(triali).targetPos=respTrials(triali-1).targetPos;
                    respTrials(triali).correctSide=respTrials(triali-1).correctSide;
                    respTrials(triali).correctTilt=respTrials(triali-1).correctTilt;
                else
                    respTrials(triali).correctResp=0; respTrials(triali).respTime=0;
                    respTrials(triali).respKey='-'; respTrials(triali).correctSide=0;
                    respTrials(triali).correctTilt=0;
                    respTrials(triali).targetFeat='noresp';
                    respTrials(triali).targetPos='noresp';
                end
            end

            % Staircase
            if staircase && triali>1 && responded
                [tiltLvls, tiltSteps, tiltChanges, lastTiltChangeSign, reversals] =...
                    do_staircase(stimFeat, tiltLvls, tiltSteps, respTrials,...
                    triali, tiltChanges, lastTiltChangeSign, reversals,...
                    minTiltsLvl, maxTiltsLvl, minTiltStep,lastRespondedTrialByFeat);
                lastRespondedTrialByFeat(trialFeat)=triali;
            end
            

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % ITI (only if no fixBreak)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            firstPass=1; tempT=GetSecs;
            while GetSecs < (tempT+trials.ITI(triali)-(ifi/2)) && fixation
                if firstPass
                    if mainvar.EEG; sendEventCode(object,port, mainvar.eITI); end
                    if mainvar.EL; Eyelink('Message', 'START_ITI'); end
                    firstPass=0;
                end
            end
        end
        tiltHistory(triali,:)=tiltLvls;
        triali=triali+1;
    end

end
