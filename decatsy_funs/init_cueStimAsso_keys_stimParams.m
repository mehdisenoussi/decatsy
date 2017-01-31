% Function that returns the cue-stimulus associations and the keys to be
% used based on the observer's group (1-4), the session and the phase he's in.  
function [condition, cueStimAsso, leftResps, rightResps, responseKeys,...
    validRatio, stims]=init_cueStimAsso_keys_stimParams(subjGroup, session, expPhase, stims)

    % Find condition depending on subject group and session
    switch session
        case 1
            if sum(subjGroup==[1, 2]); condition='feature';
            else condition='spatial';end
        case 2
            if sum(subjGroup==[1, 2]); condition='spatial';
            else condition='feature';end
    end

    % Assign cue-stim associations
    switch subjGroup
        case {1 3}
            switch condition
                case 'feature'
                    cueStimAsso=[{'vert'}; {'hori'}];
                case 'spatial'
                    cueStimAsso=[{'right'}; {'left'}];
            end
        case {2 4}
            switch condition
                case 'feature'
                    cueStimAsso=[{'hori'}; {'vert'}];
                case 'spatial'
                    cueStimAsso=[{'left'}; {'right'}];
            end
    end

    % Assign keys to be used, validity ratio and stimuli parameters depending
    % on the phase (train1, train2, ..., main)
    if strcmp(expPhase, 'train1')
        if strcmp(condition,'feature')
            leftResps={'d'}; rightResps={'k'};
        else leftResps={'v'}; rightResps={'h'};
        end
        responseKeys=[leftResps rightResps];
    else
        leftResps=[{'s'} {'d'}]; rightResps=[{'k'} {'l'}];
        responseKeys=[leftResps rightResps]; 
    end

    if strcmp(expPhase,'train4') || strcmp(expPhase,'main'); validRatio=.7;
    else validRatio=1; end

    if strcmp(expPhase,'train1') || strcmp(expPhase,'train2'); stims.contrast=1;
    else stims.contrast=.2; end

end
