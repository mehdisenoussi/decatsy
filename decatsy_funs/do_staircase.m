%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do the staircase procedure using the Levitt rule and returns
% variables that might have change 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tiltLvls, tiltSteps, tiltChanges, lastTiltChange, reversals] =...
    do_staircase(targetFeat, stimFeat, tiltLvls, tiltSteps, respTrials,...
    triali, tiltChanges, lastTiltChange, reversals, minTiltsLvl, maxTiltsLvl)

% if it is not the first trial, if we are doing a staircase and if
% the observer responded in this trial        
if strcmp(targetFeat, stimFeat(1)); targetFeatInd=1;
else targetFeatInd=2; end
tilt=tiltLvls(targetFeatInd);

if not(sum(reversals(targetFeatInd,:)))
    % 1st reversal do simple one-up-one-down
    if respTrials(triali).correctResp; tiltSign=-1;
    else tiltSign=1; end
    tilt=tilt+(tiltSign*tiltSteps(targetFeatInd));
    tiltLvls(targetFeatInd)=tilt;
    tiltChanges(targetFeatInd, triali)=tiltSign;
    if tiltChanges(targetFeatInd,triali)==-lastTiltChange(targetFeatInd)
        reversals(targetFeatInd,triali)=1;
        tiltSteps(targetFeatInd)=tiltSteps(targetFeatInd)/2.;
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
    tilt=tilt+(tiltSign*tiltSteps(targetFeatInd));

    % stores the new tilt if it doesn't exceed the tilt limits
    if tilt>minTiltsLvl && tilt<maxTiltsLvl
        fprintf('\ntiltlvl changed %i\n',tiltSign);
        tiltLvls(targetFeatInd)=tilt;
        tiltChanges(targetFeatInd, triali) = tiltSign;

        % if there is a reversal in this feature's tiltChange
        if tiltSign==-lastTiltChange(targetFeatInd)
            reversals(targetFeatInd,triali)=1;
            % takes care of the Levitt rule
            if mod(length(find(reversals(targetFeatInd,:)~=0)),2)
                % if the reversal number is odd divide tiltStep by 2
                newTiltStep=tiltSteps(targetFeatInd)/2.;
                % no minimum for tilt step
                tiltSteps(targetFeatInd)=newTiltStep;
%                         if newTiltStep>minTiltStep
%                             tiltSteps(targetFeatInd)=newTiltStep;
%                         end
            end
        end
        if tiltSign; lastTiltChange(targetFeatInd)=tiltSign; end
    end
end

%% Old code inside the script that can be replaced there if it bugs..
%         if staircase && triali>1 && responded
%             % if it is not the first trial, if we are doing a staircase and if
%             % the observer responded in this trial        
%             if strcmp(targetFeat, stimFeat(1)); targetFeatInd=1;
%             else targetFeatInd=2; end
%             tilt=tiltLvls(targetFeatInd);
% 
%             if not(sum(reversals(targetFeatInd,:)))
%                 % 1st reversal do simple one-up-one-down
%                 if respTrials(triali).correctResp; tiltSign=-1;
%                 else tiltSign=1; end
%                 tilt=tilt+(tiltSign*tiltSteps(targetFeatInd));
%                 tiltLvls(targetFeatInd)=tilt;
%                 tiltChanges(targetFeatInd, triali)=tiltSign;
%                 if tiltChanges(targetFeatInd,triali)==-lastTiltChange(targetFeatInd)
%                     reversals(targetFeatInd,triali)=1;
%                     tiltSteps(targetFeatInd)=tiltSteps(targetFeatInd)/2.;
%                 end
%                 lastTiltChange(targetFeatInd)=tiltSign;
%             else
%                 tiltSign=0;
%                 % not 1st reversal: one-up-two-down
%                 if not(respTrials(triali).correctResp)
%                    tiltSign=1; % one-up -> increase tiltLvl
%                 elseif respTrials(triali).correctResp && respTrials(triali-1).correctResp
%                     tiltSign=-1; % two-down -> decrease tiltLvl
%                 end
%                 tilt=tilt+(tiltSign*tiltSteps(targetFeatInd));
% 
%                 % stores the new tilt if it doesn't exceed the tilt limits
%                 if tilt>trials.mintiltsLvl && tilt<trials.maxtiltsLvl
%                     fprintf('\ntiltlvl changed %i\n',tiltSign);
%                     tiltLvls(targetFeatInd)=tilt;
%                     tiltChanges(targetFeatInd, triali) = tiltSign;
% 
%                     % if there is a reversal in this feature's tiltChange
%                     if tiltSign==-lastTiltChange(targetFeatInd)
%                         reversals(targetFeatInd,triali)=1;
%                         % takes care of the Levitt rule
%                         if mod(length(find(reversals(targetFeatInd,:)~=0)),2)
%                             % if the reversal number is odd divide tiltStep by 2
%                             newTiltStep=tiltSteps(targetFeatInd)/2.;
%                             % no minimum for tilt step
%                             tiltSteps(targetFeatInd)=newTiltStep;
%     %                         if newTiltStep>trials.minTiltStep
%     %                             tiltSteps(targetFeatInd)=newTiltStep;
%     %                         end
%                         end
%                     end
%                     if tiltSign; lastTiltChange(targetFeatInd)=tiltSign; end
%                 end
%             end
%         end

    
    