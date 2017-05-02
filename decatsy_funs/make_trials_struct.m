% Creates, shuffles and returns trial sequence parameters
function trials = make_trials_struct(n_trials, cueOrientations, validRatio, timing)

    trials.ITI=timing.ITIs(randi(11,1,n_trials));   
    
    trials.validity = zeros(1, n_trials);
    trials.validity(1:round(validRatio*n_trials))=1;

    trial_n=1;
    for oo = 1:(n_trials/16)
        for jj = 1:2
            for ii = 0:45:45
               for pp = -1:2:1
                   for qq = -1:2:1
                       trials.tiltDir(:,trial_n)=[pp qq];
                       trials.precue(trial_n)=ii;
                       trials.cue(trial_n)=ii;
                       if jj==1; trials.feature(:,trial_n)=[0 90];
                       elseif jj==2; trials.feature(:,trial_n)=[90 0]; end
                       trial_n=trial_n+1;
                   end
               end
            end
        end
    end

    trials.cue(~logical(trials.validity))=(~trials.cue(~logical(trials.validity)))*45;
    
    % shuffling trials
    shuffIndex=Shuffle(1:n_trials);
    trials.tiltDir=trials.tiltDir(:,shuffIndex);
    trials.feature=trials.feature(:,shuffIndex);
    trials.cue=trials.cue(shuffIndex); trials.precue=trials.precue(shuffIndex);
    trials.validity=trials.validity(shuffIndex);
    
end

