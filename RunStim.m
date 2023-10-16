function t = RunStim(tempOrder,nTrials,timings,s,t,com,keys)

tCount = 1;

if isempty(nTrials)
    %if Trial number is not defined or 0, will take length of tempOrder
    nTrials = length(tempOrder);
elseif isscalar(nTrials)
    if nTrials == 0  
        nTrials = length(tempOrder);
    elseif nTrials > 0 && length(tempOrder) == 1 
        %if tempOrder contains just one number, will use the nTrials for number of repetitions
        tempOrder = repmat(tempOrder,1,nTrials);
    end
elseif size(nTrials,2) == 2
    %if tempOrder contains just one number but nTrials two numbers, it will
    %start the loop not with 1 but with the sum of both nTrials numbers
    if length(tempOrder) == 1
        tempOrder = [t.tmp.temp-t.log.awis.thresh tempOrder];
        nTrials = nTrials(1) + nTrials(2);
        tCount = nTrials;
    end
end

%tempOrder can be defined as numbers added to pain threshold or as actual
%temperatures, checking through one or two digit input
if all((floor(log10(abs(tempOrder)+1))+1)==1)
    temps = tempOrder + t.log.awis.thresh;
elseif all((floor(log10(abs(tempOrder)+1))+1)==2)
    temps = tempOrder;
else
    disp(tempOrder);
    error('No reasonable temps detected, please check numbers above');
end
  
%check plausibility of temps
if min(temps) < t.glob.minTemp-2 && max(temps) > t.glob.maxTemp
    warning('Attention: temps below %d or above %d detected!!!!!!!!!!!!!',t.glob.minTemp-2,t.glob.maxTemp);
end
    
if any(temps > t.glob.maxTemp)
    if sum(temps > t.glob.maxTemp) < 3
        temps(temps > t.glob.maxTemp) = t.glob.maxTemp;
        fprintf('%d trial(s) with higher temp detected, lowering to %d°C',sum(temps > t.glob.maxTemp),t.glob.maxTemp);
    elseif sum(temps > t.glob.maxTemp) > 2
        disp(temps);
        error('More than 2 trials above %d°C detected, please check participant ratings',t.glob.maxTemp);
    end
elseif any(temps < t.glob.minTemp-2)
    if sum(temps < t.glob.minTemp-2) < 3
        disp(temps);
        fprintf('%d trial(s) with lower temp detected, increasing to %d°C',sum(temps < t.glob.minTemp-2),t.glob.minTemp-2);
    elseif sum(temps < t.glob.minTemp-2) > 2
        disp(temps);
        error('More than 2 temps below %d°C detected, please check participant ratings',t.glob.minTemp-2);
    end
end

fprintf('\nFollowing temps will be applied:\n');
fprintf(' %3.1f  ',temps);
fprintf('\n');

t.tmp.scaleInitVAS = round(26+(76-26).*rand(1,nTrials));
    
for nTrial = tCount:nTrials 
     
    fprintf('\n=======TRIAL %d of %d=======\n',nTrial,nTrials);
    
    %first ITI
    if nTrial == 1
        Screen('FillRect', s.wHandle, s.white, s.Fix1);
        Screen('FillRect', s.wHandle, s.white, s.Fix2);
        tITIStart = Screen('Flip',s.wHandle);
        
        fprintf('First ITI of %1.0f seconds\n',t.glob.firstITI);
        while GetSecs < tITIStart + t.glob.firstITI
            [abort] = LoopBreaker(keys);
            if abort; return; end
        end
    end
    
    %cue
    if t.glob.cueing == 1 % else we don't want the red cross
        Screen('FillRect', s.wHandle, s.red, s.Fix1);
        Screen('FillRect', s.wHandle, s.red, s.Fix2);
        tCrossOn = Screen('Flip',s.wHandle);
        fprintf('Cue %1.0f seconds\n',timings.Cue(nTrial));
        while GetSecs < tCrossOn + timings.Cue(nTrial)
            [abort] = LoopBreaker(keys);
            if abort; return; end
        end
    end
    
    %pain
    Screen('FillRect', s.wHandle, s.red, s.Fix1);
    Screen('FillRect', s.wHandle, s.red, s.Fix2);
    Screen('Flip',s.wHandle);
    
    [abort] = ApplyTemp(temps(nTrial),t.calib.stimDur,t,com);
    if abort; break; end
    
    % brief blank screen prior to rating
    tBlankOn = Screen('Flip',s.wHandle);
    while GetSecs < tBlankOn + t.glob.sBlank end
    
    % VAS rating
    fprintf('VAS...\n');
    
    t = VASScale(nTrial,s,t,keys);
    
    %save results
    t.tmp.temp(nTrial) = temps(nTrial);
    LogRating(t);
    save(t.saveFile, 't');
    
    %ITI
    Screen('FillRect', s.wHandle, s.white, s.Fix1);
    Screen('FillRect', s.wHandle, s.white, s.Fix2);
    tITIStart = Screen('Flip',s.wHandle);
    
    fprintf('Remaining ITI %1.0f seconds...\n',timings.ITI(nTrial));
    countedDown = 1;
    while GetSecs < tITIStart + timings.ITI(nTrial)
        [countedDown] = CountDown(GetSecs-tITIStart,countedDown,'');
        [abort] = LoopBreaker(keys);
        if abort; return; end
    end
    
    if abort
        QuickCleanup;
        return;
    end
    
end
