% Append a particular trial parameters to the trial sequence (e.g. if the
% obsever missed a trial, this trial is not lost it is done at the end of
% the trial sequence)
function trials = append_trial(trials, triali)
    trials.feature(:,end+1)=trials.feature(:,triali);
    trials.tiltDir(:,end+1)=trials.tiltDir(:,triali);
    trials.validity(end+1)=trials.validity(triali);
    trials.precue(end+1)=trials.precue(triali);
    trials.cue(end+1)=trials.cue(triali);
    trials.ITI(end+1)=trials.ITI(triali);
end