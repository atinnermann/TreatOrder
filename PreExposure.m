function PreExposure(s,t,com,keys)

fprintf('\n=======PreExposure=======\n');


Screen('FillRect', s.wHandle, s.white, s.Fix1);
Screen('FillRect', s.wHandle, s.white, s.Fix2);
tITIStart = Screen('Flip',s.wHandle);

%fprintf('ITI start at %1.1fs\n',GetSecs-tStartScript);
fprintf('First ITI of %1.0f seconds\n',t.exp.wrapITI);
while GetSecs < tITIStart + t.exp.wrapITI
    [abort] = LoopBreaker(keys);
    if abort; return; end
end

for nTrial = 1:t.exp.nTrials
        
    %pain
    Screen('FillRect', s.wHandle, s.red, s.Fix1);
    Screen('FillRect', s.wHandle, s.red, s.Fix2);
    Screen('Flip',s.wHandle);
    
    [abort] = ApplyTemp(t.exp.temp,t.exp.dur,t,com);
    
    %ITI
    Screen('FillRect', s.wHandle, s.white, s.Fix1);
    Screen('FillRect', s.wHandle, s.white, s.Fix2);
    tITIStart = Screen('Flip',s.wHandle);
    
    if nTrial == t.exp.nTrials
        cITI = t.exp.wrapITI;
    else
        cITI = t.exp.iti;
    end
    
    fprintf('Remaining ITI %1.0f seconds...\n',cITI);
    countedDown = 1;
    while GetSecs < tITIStart + cITI
        [countedDown] = CountDown(GetSecs-tITIStart,countedDown,'');
        [abort] = LoopBreaker(keys);
        if abort; return; end
    end
    
    if abort
        QuickCleanup;
        return;
    end
end


