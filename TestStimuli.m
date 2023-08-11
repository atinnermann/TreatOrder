function TestStimuli(s,t,com,keys)


fprintf('\n=======TestStimuli=======\n');

Screen('FillRect', s.wHandle, s.white, s.Fix1);
Screen('FillRect', s.wHandle, s.white, s.Fix2);
tITIStart = Screen('Flip',s.wHandle);

%fprintf('ITI start at %1.1fs\n',GetSecs-tStartScript);
fprintf('First ITI of %1.0f seconds\n',t.glob.firstITI);
while GetSecs < tITIStart + t.glob.firstITI
    [abort] = LoopBreaker(keys);
    if abort; return; end
end

for t = 1:length(t.testStim.temps)

%pain
Screen('FillRect', s.wHandle, s.red, s.Fix1);
Screen('FillRect', s.wHandle, s.red, s.Fix2);
Screen('Flip',s.wHandle);

[abort] = ApplyTemp(t.testStim.temps(t),t.testStim.dur,t,com);

%ITI
Screen('FillRect', s.wHandle, s.white, s.Fix1);
Screen('FillRect', s.wHandle, s.white, s.Fix2);
tITIStart = Screen('Flip',s.wHandle);

fprintf('Remaining ITI %1.0f seconds...\n',t.testStim.ITI);
countedDown = 1;
while GetSecs < tITIStart + t.testStim.ITI
    [countedDown] = CountDown(GetSecs-tITIStart,countedDown,'');
    [abort] = LoopBreaker(keys);
    if abort; return; end
end

if abort
    QuickCleanup;
    return;
end

end
