%% Set Marker for CED and BrainVision Recorder
function SendTrigger(address,port,dur)
% Send pulse to CED for SCR, thermode, digitimer

if strcmp(hostname,'blab0')
    outp(address,port);
    WaitSecs(dur);
    outp(address,0);
end

end
