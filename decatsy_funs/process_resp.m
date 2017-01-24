function [respTrials, respFixCol] = process_resp(respTrials, trials, triali,...
    condition, expPhase, cueStimAsso, stimFeat, leftResps, rightResps, responseKey)
    % find out where and what the target was
    switch condition
        case 'feature'
            % if feature condition find out which cue it is, 
            % then which orientation the cue is associated with
            % then where this orientation was (left or right)
            targetFeat=cueStimAsso(logical(trials.cue(triali))+1);
            if strcmp(targetFeat, 'hori')
                if trials.feature(1,triali)==90;targetPos='left';
                else targetPos='right'; end
            elseif strcmp(targetFeat, 'vert')
                if trials.feature(1,triali)==0;targetPos='left';
                else targetPos='right'; end
            end
        case 'spatial'
            % if spatial condition find out which cue it is to get
            % which side it is associated with
            targetPos=cueStimAsso(logical(trials.cue(triali))+1);
            if strcmp(targetPos,'left');
                targetFeat=stimFeat(logical(trials.feature(1,triali))+1);
            else targetFeat=stimFeat(logical(trials.feature(2,triali))+1);
            end
    end
    respTrials(triali).targetFeat=targetFeat;
    respTrials(triali).targetPos=targetPos;
    
    % Train 1 phase is an exception
    if strcmp(expPhase, 'train1')
        if strcmp(condition,'feature')
            if sum(strcmp(leftResps, responseKey)); respTrials(triali).respSide='left';
            else sum(strcmp(rightResps, responseKey)); respTrials(triali).respSide='right'; end
            respTrials(triali).correctSide=strcmp(targetPos, respTrials(triali).respSide);
        else
            respTrials(triali).correctSide=...
                (strcmp(targetFeat,stimFeat(1)) && strcmp(responseKey,leftResps)...
                || strcmp(targetFeat,stimFeat(2)) && strcmp(responseKey,rightResps));
        end
        respTrials(triali).correctTilt=1;
    else
        % once we know where the target was, we rate if the pressed 
        % key was on the correct side
        if sum(strcmp(leftResps, responseKey)); respTrials(triali).respSide='left'; 
        else sum(strcmp(rightResps, responseKey)); respTrials(triali).respSide='right'; end
        respTrials(triali).correctSide=strcmp(targetPos, respTrials(triali).respSide);

        % if the observer responded on the correct side, check if reported tilt is correct
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
    end
    respTrials(triali).correctResp=...
        respTrials(triali).correctTilt==1 && respTrials(triali).correctSide;
    if respTrials(triali).correctResp; respFixCol=[0 1 0];                
    else respFixCol=[1 0 0]; end
    
end