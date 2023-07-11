%% display string during countdown
function [countedDown] = CountDown(secs, countedDown, countString)
    if secs>countedDown
        fprintf('%s', countString);
        countedDown = ceil(secs);
    end
end