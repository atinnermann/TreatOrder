function PreExposure(s,t,com,keys)


startTime = GetSecs;

fprintf('\n=======PreExposure=======\n');

Screen('FillRect', s.wHandle, s.white, s.Fix1);
Screen('FillRect', s.wHandle, s.white, s.Fix2);
tITIStart = Screen('Flip',s.wHandle);

%fprintf('ITI start at %1.1fs\n',GetSecs-tStartScript);
fprintf('First ITI of %1.0f seconds\n',t.exp.ITI);
while GetSecs < tITIStart + t.exp.ITI
    [abort] = LoopBreaker(keys);
    if abort; return; end
end

%pain
Screen('FillRect', s.wHandle, s.red, s.Fix1);
Screen('FillRect', s.wHandle, s.red, s.Fix2);
Screen('Flip',s.wHandle);

[abort] = ApplyTemp(t.exp.temp,t.exp.dur,t,com);

%ITI
Screen('FillRect', s.wHandle, s.white, s.Fix1);
Screen('FillRect', s.wHandle, s.white, s.Fix2);
tITIStart = Screen('Flip',s.wHandle);

fprintf('Remaining ITI %1.0f seconds...\n',t.exp.ITI);
countedDown = 1;
while GetSecs < tITIStart + t.exp.ITI
    [countedDown] = CountDown(GetSecs-tITIStart,countedDown,'');
    [abort] = LoopBreaker(keys);
    if abort; return; end
end

if abort
    QuickCleanup;
    return;
end


