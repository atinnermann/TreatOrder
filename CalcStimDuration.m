%% returns a vector with riseTime, sPlateau and fallTime for the target stimulus
function t = CalcStimDuration(temp,dur,t)
    diff        = abs(temp-t.glob.baseTemp);
    riseTime    = diff/t.glob.riseSpeed;
    fallTime    = diff/t.glob.fallSpeed;

    t.tmp.stimDuration = [riseTime dur fallTime];
end