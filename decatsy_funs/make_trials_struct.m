% Creates, shuffles and returns trial sequence parameters
function trials = make_trials_struct(n_trials, cueOrientations, validRatio, timing)

    trials.feature=repmat([0 90]',1,n_trials);
    % tilt is randomly the same on the two gratings
    trials.tiltDir=[Shuffle(repmat([-1 1],1,(n_trials/2)));...
        Shuffle(repmat([-1 1],1,ceil(n_trials/2)))];
    trials.ITI=timing.ITIs(randi(11,1,n_trials));
    
    trials.validity=zeros(1, n_trials);
    trials.validity(1:round(validRatio*n_trials))=1;
    trials.precue=repmat(cueOrientations, 1, ceil(n_trials/2));
    trials.cue=repmat(cueOrientations, 1, ceil(n_trials/2));
    trials.cue(~logical(trials.validity))=(~trials.cue(~logical(trials.validity)))*45;
    
    % shuffling trials
    trials.feature=Shuffle(trials.feature);
    shuffIndex=Shuffle(1:n_trials);
    trials.cue=trials.cue(shuffIndex); trials.precue=trials.precue(shuffIndex);
    
end

