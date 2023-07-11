 function [d] = DetermineITIandCue(nStims,mMITIJ,mMCJ)
        
        nITIJitter        = (max(mMITIJ)-min(mMITIJ))/(nStims-1); %yields the increment size required for length(sequence) trials
        sITIJitter        = min(mMITIJ):nITIJitter:max(mMITIJ);
        nCueJitter        = (max(mMCJ)-min(mMCJ))/(nStims-1); %yields the increment size required for length(sequence) trials
        sCueJitter        = min(mMCJ):nCueJitter:max(mMCJ);
        
        if isempty(sITIJitter) sITIJitter(nStims)=mean(mMITIJ); end % then max(mMITIJ)==min(mMITIJ)
        if isempty(sCueJitter) sCueJitter(nStims)=mean(mMCJ); end % then max(mMCJ)==min(mMCJ)
        
        % construct ITI list matching the stimulus sequence
        d.ITI = sITIJitter(randperm(length(sITIJitter)));
%         d.firstITI = d.ITIs(end); % the last ITI will be ignored anyway, so we may as well use it as the first
        
        d.Cue = sCueJitter(randperm(length(sCueJitter)));
%         d.firstCue = d.Cues(end); % the last cue will be ignored anyway, so we may as well use it as the first
        
    end