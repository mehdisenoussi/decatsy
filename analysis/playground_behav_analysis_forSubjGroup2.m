targetSide=zeros(2,n_trials);
corrRespSide=zeros(1,n_trials);
corrRespTilt=zeros(1,n_trials);
for triali=1:n_trials
    switch logical(cue(triali))
        case 0
            if gratingOriL(triali)>45; targetSide(1,triali)=1;
            else targetSide(2,triali)=1; end
        case 1
            if gratingOriL(triali)<45; targetSide(1,triali)=1;
            else targetSide(2,triali)=1; end
    end
    if targetSide(1,triali) && sum(strcmp(respKey(triali),leftResps))
        corrRespSide(triali)=1;
    elseif targetSide(2,triali) && sum(strcmp(respKey(triali),rightResps))
        corrRespSide(triali)=1;
    end
    if corrRespSide(triali)
        if targetSide(1,triali); targetOri=gratingOriL(triali);
        else targetOri=gratingOriR(triali); end
            
        if targetOri<45
            if targetOri<0; corrRespTilt(triali)=any(strcmp(respKey(triali),{'s' 'k'}));
            else corrRespTilt(triali)=any(strcmp(respKey(triali),{'d' 'l'}));
            end
        else
            if targetOri<90; corrRespTilt(triali)=any(strcmp(respKey(triali),{'s' 'k'}));
            else corrRespTilt(triali)=any(strcmp(respKey(triali),{'d' 'l'}));
            end
        end 
    end
end

