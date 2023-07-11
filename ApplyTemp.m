function [abort] = ApplyTemp(temp,dur,t,com)

abort = 0;
t = CalcStimDuration(temp,dur,t);

fprintf('Stimulus initiated %1.1f°C...\n',temp);
tHeatOn = GetSecs;
countedDown = 1;

if com.thermoino == 0
    while GetSecs < tHeatOn + sum(t.tmp.stimDuration) 
    end
elseif com.thermoino
    UseThermoino('Trigger'); % start next stimulus
    UseThermoino('Set',temp); % open channel for arduino to ramp up
    
    while GetSecs < tHeatOn + sum(t.tmp.stimDuration(1:2))
        [countedDown] = CountDown(GetSecs-tHeatOn,countedDown,'.');
    end
    
    fprintf('\n');
    UseThermoino('Set',t.glob.baseTemp); % open channel for arduino to ramp down
    
    if ~abort
        while GetSecs < tHeatOn + sum(t.tmp.stimDuration)
            [countedDown] = CountDown(GetSecs-tHeatOn,countedDown,'.');
            [abort] = LoopBreaker;
            if abort; return; end
        end
    else
        return;
    end
elseif thermoino == 2
    %Send trigger
    %%%this part is missing%%%%
    %either SendTrigger() if that works by now 
    %or implement cogent with outp
    
    while GetSecs < tHeatOn + sum(t.tmp.stimDuration)
        [countedDown] = CountDown(GetSecs-tHeatOn,countedDown,'.');
        [abort] = LoopBreaker;
        if abort; return; end
    end
end

fprintf('Stimulus concluded...\n');

end