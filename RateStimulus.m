function [painful,rateDur]=RateStimulus(s,t,keys)

painful = -1; % for security; if painful is not overwritten, will abort in WaitRemainingITI

% await rating within a time frame that leaves enough time to adjust the stimulus
tRateOn = GetSecs;

fprintf('Not painful or painful?\n');

if strcmp(s.hostname,'stimpc1')
    if strcmp(s.language,'de')
        keyNotPainful = '[linker Knopf]';
        keyPainful = '[rechter Knopf]';
    elseif strcmp(s.language,'en')
        keyNotPainful = '[left button]';
        keyPainful = '[right button]';
    end
else
    keyNotPainful = '(<-)';
    keyPainful = '(->)';
end
if strcmp(s.language,'de')
    [s.screenRes.width, s.startY] = DrawFormattedText(s.wHandle, ['Nicht schmerzhaft ' keyNotPainful ' oder mindestens leicht schmerzhaft ' keyPainful '?'], 'center', s.startY, s.white);
elseif strcmp(language,'en')
    [s.screenRes.width, s.startY] = DrawFormattedText(s.wHandle, ['Not painful ' keyNotPainful ' or at least slightly painful ' keyPainful '?'], 'center', s.startY, s.white);
end

Screen('Flip',s.wHandle);
% WaitSecs(t.sBlank);
%KbQueueRelease;

while GetSecs < tRateOn + t.glob.ratingDur
    [keyIsDown, ~, keyCode] = KbCheck();
    if keyIsDown
        if find(keyCode) == keys.name.painful
            painful = 1;
            break;
        elseif find(keyCode) == keys.name.notPainful
            painful = 0;
            break;
        elseif find(keyCode) == keys.name.abort
            painful = -1;
            break;
        end
    end
end

rateDur = GetSecs() - tRateOn;

end