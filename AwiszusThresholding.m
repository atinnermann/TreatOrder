function t = AwiszusThresholding(timings,s,t,com,keys)
% iteratively increase or decrease the target temperature to approximate pain threshold

temp = t.awis.temp;

t.log.awis.rating = NaN(t.awis.nTrials,2);

for nTrial = 1:t.awis.nTrials
    
    fprintf('\n=======TRIAL %d of %d=======\n',nTrial,t.awis.nTrials);
    
    %first ITI
    if nTrial == 1
        Screen('FillRect', s.wHandle, s.white, s.Fix1);
        Screen('FillRect', s.wHandle, s.white, s.Fix2);
        tITIStart = Screen('Flip',s.wHandle);
        
        %fprintf('ITI start at %1.1fs\n',GetSecs-tStartScript);
        fprintf('First ITI of %1.0f seconds...\n',t.glob.firstITI);
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
        fprintf('Cue of %1.0f seconds ...\n',timings.Cue(nTrial));
        while GetSecs < tCrossOn + timings.Cue(nTrial)
            [abort] = LoopBreaker(keys);
            if abort; return; end
        end
    end
    
    %pain
    Screen('FillRect', s.wHandle, s.red, s.Fix1);
    Screen('FillRect', s.wHandle, s.red, s.Fix2);
    Screen('Flip',s.wHandle);
    [abort] = ApplyTemp(temp,t.awis.stimDur,t,com);
    if abort; break; end
    
    %rating
    WaitSecs(t.glob.sBlank);
    [painful,rateDur] = RateStimulus(s,t,keys);
    if painful == -1 && t.glob.debug == 1
        painful = 0;
    end
    while painful == -1
        if strcmp(s.language,'de')
            [s.screenRes.width, s.startY]=DrawFormattedText(s.wHandle, 'Sie haben keine Bewertung abgegeben! Wiederholung', 'center', s.startY, s.white);
        else
            [s.screenRes.width, s.startY]=DrawFormattedText(s.wHandle, 'No rating provided! Please try again', 'center', s.startY, s.white);
        end
        Screen('Flip',s.wHandle);
        WaitSecs(1);
        [painful,rateDur] = RateStimulus(s,t,keys);
    end
    
    %save results
    rating(nTrial,1) = temp;
    rating(nTrial,2) = painful;
    save(t.tmp.saveName, 'rating');
    
    t.log.awis.rating(nTrial,:) = rating(nTrial,:);
    save(t.saveFile, 't');
    
    %calculate new temp based on previous rating
    [temp,t.awis.post]  = DeriveNewTemp(temp,painful,t.awis.tRange,t.awis.indvar,t.awis.post); % after subject's rating, this will display the temp intended for the upcoming stimulus
    
    %ITI, if last trail, ITI is shorter
    Screen('FillRect', s.wHandle, s.white, s.Fix1);
    Screen('FillRect', s.wHandle, s.white, s.Fix2);
    tITIStart = Screen('Flip',s.wHandle);
    
    if nTrial == t.awis.nTrials
        sITIRemaining = t.glob.lastITI;
    else
        sITIRemaining = timings.ITI(nTrial)-rateDur;
    end
    
    fprintf('Remaining ITI of %1.0f seconds...',sITIRemaining);
    countedDown = 1;
    while GetSecs < tITIStart + sITIRemaining
        [countedDown] = CountDown(GetSecs-tITIStart,countedDown,'.');
        [abort] = LoopBreaker(keys);
        if abort; return; end
    end
    
    if abort
        QuickCleanup;
        return;
    end
    
end

if temp < t.glob.minThresh
    temp = t.glob.minThresh;
elseif temp > t.glob.maxThresh
    temp = t.glob.maxThresh;
end

t.log.awis.thresh = temp;
save(t.saveFile, 't');

%     fprintf('\n\nThreshold determined around %1.1f°C, after %d trials.\nThreshold data saved under %s%s.mat and %s.mat.\n',AwThreshold,t.nTrials,savePath,fileName,fileNameResults);

end